// JSONFormattable extraction utilities for Embedded Swift (WASM)
// Simple byte-based parsing without Foundation
// /// Extract a string value for a given key from a JSONFormattable string
public func extractJSONString(_ json: String, key: String) -> String? {
  let pattern = "\"\(key)\":\""

  return json.utf8.withContiguousStorageIfAvailable { jsonBytes -> String? in
    let patternBytes = Array(pattern.utf8)
    let patternCount = patternBytes.count

    guard jsonBytes.count >= patternCount else { return nil }

    // Find pattern start
    var startIndex = -1
    for i in 0...(jsonBytes.count - patternCount) {
      var match = true
      for j in 0..<patternCount {
        if jsonBytes[i + j] != patternBytes[j] {
          match = false
          break
        }
      }
      if match {
        startIndex = i + patternCount
        break
      }
    }

    guard startIndex >= 0 && startIndex < jsonBytes.count else { return nil }

    // Find closing quote (handle escaped quotes)
    var endIndex = startIndex
    var prevWasBackslash = false
    while endIndex < jsonBytes.count {
      let byte = jsonBytes[endIndex]
      if byte == 34 && !prevWasBackslash {  // 34 = '"'
        break
      }
      prevWasBackslash = (byte == 92)  // 92 = '\'
      endIndex += 1
    }

    guard endIndex > startIndex && endIndex < jsonBytes.count else { return nil }

    // Extract value
    let valueBytes = Array(jsonBytes[startIndex..<endIndex])
    return String(decoding: valueBytes, as: UTF8.self)
  } ?? nil
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
