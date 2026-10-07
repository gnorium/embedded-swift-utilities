// JSONFormattable extraction utilities for Embedded Swift (WASM)
// Simple byte-based parsing without Foundation
// /// Extract a string value for a given key from a JSONFormattable string
public func extractJSONString(_ json: String, key: String) -> String? {
  // The quoted key only; the colon and the value's opening quote are matched
  // with JSON's optional whitespace around them, so `"path": "x"`—how a
  // model writes tool arguments—is found as readily as `"path":"x"`.
  let pattern = "\"\(key)\""
  let patternBytes = Array(pattern.utf8)
  let patternCount = patternBytes.count

  // Always copy to a contiguous Array—`withContiguousStorageIfAvailable` returns
  // nil for many WASM/bridged strings (esp. large SSE chunk payloads), which used
  // to make a watch silently drop the entire transcript.
  let jsonBytes = Array(json.utf8)
  guard jsonBytes.count >= patternCount else { return nil }

  func isSpace(_ byte: UInt8) -> Bool {
    byte == 32 || byte == 9 || byte == 10 || byte == 13
  }

  // Find the key, then `:` and `"` past any whitespace.
  var startIndex = -1
  for i in 0...(jsonBytes.count - patternCount) {
    var match = true
    for j in 0..<patternCount {
      if jsonBytes[i + j] != patternBytes[j] {
        match = false
        break
      }
    }
    guard match else { continue }
    var k = i + patternCount
    while k < jsonBytes.count, isSpace(jsonBytes[k]) { k += 1 }
    guard k < jsonBytes.count, jsonBytes[k] == 58 else { continue }  // ':'
    k += 1
    while k < jsonBytes.count, isSpace(jsonBytes[k]) { k += 1 }
    guard k < jsonBytes.count, jsonBytes[k] == 34 else { continue }  // '"'
    startIndex = k + 1
    break
  }

  guard startIndex >= 0 && startIndex < jsonBytes.count else { return nil }

  // Find closing quote—honor even/odd backslash runs (\\") correctly.
  var endIndex = startIndex
  var escaped = false
  while endIndex < jsonBytes.count {
    let byte = jsonBytes[endIndex]
    if byte == 92 {  // '\'
      escaped = !escaped
    } else if byte == 34 && !escaped {  // '"'
      break
    } else {
      escaped = false
    }
    endIndex += 1
  }

  guard endIndex > startIndex && endIndex < jsonBytes.count else { return nil }

  let valueBytes = Array(jsonBytes[startIndex..<endIndex])
  let raw = String(decoding: valueBytes, as: UTF8.self)
  return decodeJSONEscapes(raw)
}

/// Decode JSON string-body escapes (`\n`, `\"`, `\\`, `\uXXXX`, …) into real characters.
/// Byte-level—Embedded Swift has no `Unicode.Scalar`.
public func decodeJSONEscapes(_ raw: String) -> String {
  let bytes = Array(raw.utf8)
  var result: [UInt8] = []
  result.reserveCapacity(bytes.count)
  var i = 0
  while i < bytes.count {
    if bytes[i] != 92 {  // not '\'
      result.append(bytes[i])
      i += 1
      continue
    }
    guard i + 1 < bytes.count else {
      result.append(92)
      break
    }
    switch bytes[i + 1] {
    case 110: result.append(10)  // \n
    case 114: result.append(13)  // \r
    case 116: result.append(9)  // \t
    case 34: result.append(34)  // \"
    case 92: result.append(92)  // \\
    case 47: result.append(47)  // \/
    case 98: result.append(8)  // \b
    case 102: result.append(12)  // \f
    case 117:  // \uXXXX—keep for decodeUnicodeEscapes
      result.append(92)
      result.append(117)
      i += 2
      continue
    default:
      result.append(bytes[i + 1])
    }
    i += 2
  }
  return decodeUnicodeEscapes(String(decoding: result, as: UTF8.self))
}

/// Extract a numeric integer value for a given key from a JSON string (e.g. "width":123)
public func extractJSONInt(_ json: String, key: String) -> Int? {
  let utf8 = Array(json.utf8)
  let pattern = Array("\"\(key)\":".utf8)
  let patternCount = pattern.count
  guard utf8.count >= patternCount else { return nil }

  for i in 0...(utf8.count - patternCount) {
    var match = true
    for j in 0..<patternCount {
      if utf8[i + j] != pattern[j] { match = false; break }
    }
    if !match { continue }

    var valStart = i + patternCount
    // Skip whitespace
    while valStart < utf8.count, utf8[valStart] == 32 { valStart += 1 }
    guard valStart < utf8.count else { return nil }
    // Parse integer (optionally negative)
    var isNeg = false
    if utf8[valStart] == 45 { isNeg = true; valStart += 1 }
    guard valStart < utf8.count else { return nil }
    var result = 0
    var pos = valStart
    while pos < utf8.count, utf8[pos] >= 48, utf8[pos] <= 57 {
      result = result * 10 + Int(utf8[pos] - 48)
      pos += 1
    }
    guard pos > valStart else { return nil }
    return isNeg ? -result : result
  }
  return nil
}

/// A JSON object's top-level fields in the order written: each key with its
/// value—a string's decoded, anything else (a number, `true`, an array, an
/// object) as written. Empty for anything that is not an object. Byte-level,
/// as the rest of this file.
public func jsonTopLevelFields(_ json: String) -> [(String, String)] {
  let bytes = Array(json.utf8)
  func isSpace(_ byte: UInt8) -> Bool { byte == 32 || byte == 9 || byte == 10 || byte == 13 }
  var i = 0
  while i < bytes.count, isSpace(bytes[i]) { i += 1 }
  guard i < bytes.count, bytes[i] == 123 else { return [] }  // '{'
  i += 1

  // The end of the string whose opening quote is at `start`: the index of
  // its closing quote.
  func stringEnd(_ start: Int) -> Int? {
    var k = start + 1
    var escaped = false
    while k < bytes.count {
      if bytes[k] == 92 { escaped = !escaped } else if bytes[k] == 34 && !escaped { return k } else { escaped = false }
      k += 1
    }
    return nil
  }

  var fields: [(String, String)] = []
  while i < bytes.count {
    while i < bytes.count, isSpace(bytes[i]) || bytes[i] == 44 { i += 1 }  // ','
    guard i < bytes.count, bytes[i] == 34, let keyEnd = stringEnd(i) else { break }
    let key = decodeJSONEscapes(String(decoding: Array(bytes[(i + 1)..<keyEnd]), as: UTF8.self))
    i = keyEnd + 1
    while i < bytes.count, isSpace(bytes[i]) { i += 1 }
    guard i < bytes.count, bytes[i] == 58 else { break }  // ':'
    i += 1
    while i < bytes.count, isSpace(bytes[i]) { i += 1 }
    guard i < bytes.count else { break }
    if bytes[i] == 34 {
      guard let end = stringEnd(i) else { break }
      fields.append((key, decodeJSONEscapes(String(decoding: Array(bytes[(i + 1)..<end]), as: UTF8.self))))
      i = end + 1
      continue
    }
    // A number, a literal, an array or an object: up to the comma or brace
    // that ends it at this depth, strings inside skipped whole.
    let start = i
    var depth = 0
    while i < bytes.count {
      let byte = bytes[i]
      if byte == 34, let end = stringEnd(i) { i = end + 1; continue }
      if byte == 91 || byte == 123 { depth += 1 }  // '[' '{'
      if byte == 93 || byte == 125 {  // ']' '}'
        if depth == 0 { break }
        depth -= 1
      }
      if byte == 44 && depth == 0 { break }
      i += 1
    }
    var end = i
    while end > start, isSpace(bytes[end - 1]) { end -= 1 }
    fields.append((key, String(decoding: Array(bytes[start..<end]), as: UTF8.self)))
    if i < bytes.count, bytes[i] == 125 { break }
  }
  return fields
}
