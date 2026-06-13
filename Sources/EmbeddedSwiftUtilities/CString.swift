// Keep this for C interop if needed, but prefer String.utf8.count where possible
public func cStringLength(_ ptr: UnsafePointer<CChar>) -> Int {
  var length = 0
  while ptr[length] != 0 {
    length += 1
  }
  return length
}

public func stringIsEmpty(_ string: String) -> Bool {
  return Array(string.utf8).isEmpty
}

public func emptyString() -> String {
  return String(decoding: [], as: UTF8.self)
}

public func toString(_ staticString: StaticString) -> String {
  return staticString.withUTF8Buffer { buffer in
    return String(decoding: buffer, as: UTF8.self)
  }
}

/// ASCII-only lowercase conversion (WASM-safe, avoids Unicode normalization)
public func stringLowercased(_ string: String) -> String {
  let utf8 = Array(string.utf8)
  var result: [UInt8] = []
  result.reserveCapacity(utf8.count)
  for byte in utf8 {
    result.append((byte >= 65 && byte <= 90) ? byte + 32 : byte)
  }
  return String(decoding: result, as: UTF8.self)
}

/// ASCII-only uppercase conversion (WASM-safe, avoids Unicode normalization)
public func stringUppercased(_ string: String) -> String {
  let utf8 = Array(string.utf8)
  var result: [UInt8] = []
  result.reserveCapacity(utf8.count)
  for byte in utf8 {
    result.append((byte >= 97 && byte <= 122) ? byte - 32 : byte)
  }
  return String(decoding: result, as: UTF8.self)
}

/// ASCII-only capitalization (WASM-safe, avoids Unicode normalization)
public func stringCapitalized(_ string: String) -> String {
  let utf8 = Array(string.utf8)
  if utf8.isEmpty { return "" }

  var result = utf8
  // Capitalize first byte if it's a-z
  if result[0] >= 97 && result[0] <= 122 {
    result[0] -= 32
  }
  return String(decoding: result, as: UTF8.self)
}

public func stringEquals(_ lhs: String, _ rhs: String) -> Bool {
  let lBytes = Array(lhs.utf8)
  let rBytes = Array(rhs.utf8)
  if lBytes.count != rBytes.count { return false }
  for i in 0..<lBytes.count {
    if lBytes[i] != rBytes[i] { return false }
  }
  return true
}

public func stringEquals(_ lhs: String?, _ rhs: String?) -> Bool {
  switch (lhs, rhs) {
  case (.none, .none): return true
  case (.some(let l), .some(let r)): return stringEquals(l, r)
  default: return false
  }
}

public func stringEquals(_ string: String, _ staticString: StaticString) -> Bool {
  return staticString.withUTF8Buffer { buffer in
    let sBytes = Array(string.utf8)
    if sBytes.count != buffer.count { return false }
    for i in 0..<buffer.count {
      if sBytes[i] != buffer[i] { return false }
    }
    return true
  }
}

/// Lexicographic comparison by UTF-8 bytes (safe for ASCII strings like ISO 8601 timestamps)
public func stringLessThanOrEqual(_ lhs: String, _ rhs: String) -> Bool {
  return stringCompare(lhs, rhs) <= 0
}

/// Lexicographic comparison by UTF-8 bytes. Returns negative if lhs < rhs, 0 if equal, positive if lhs > rhs.
public func stringCompare(_ lhs: String, _ rhs: String) -> Int {
  let bytesA = Array(lhs.utf8)
  let bytesB = Array(rhs.utf8)
  let minLen = bytesA.count < bytesB.count ? bytesA.count : bytesB.count
  for i in 0..<minLen {
    if bytesA[i] != bytesB[i] {
      return Int(bytesA[i]) - Int(bytesB[i])
    }
  }
  return bytesA.count - bytesB.count
}

public func stringContains(_ haystack: String, _ needle: String) -> Bool {
  return stringIndexOf(haystack, needle) != nil
}

public func stringStartsWith(_ string: String, _ prefix: StaticString) -> Bool {
  return prefix.withUTF8Buffer { buffer in
    let sBytes = Array(string.utf8)
    if sBytes.count < buffer.count { return false }
    for i in 0..<buffer.count {
      if sBytes[i] != buffer[i] { return false }
    }
    return true
  }
}

public func stringStartsWith(_ string: String, _ prefix: String) -> Bool {
  let sBytes = Array(string.utf8)
  let pBytes = Array(prefix.utf8)
  guard sBytes.count >= pBytes.count else { return false }
  for i in 0..<pBytes.count {
    if sBytes[i] != pBytes[i] { return false }
  }
  return true
}

public func stringEndsWith(_ string: String, _ suffix: String) -> Bool {
  let sBytes = Array(string.utf8)
  let suffixBytes = Array(suffix.utf8)
  guard sBytes.count >= suffixBytes.count else { return false }
  let offset = sBytes.count - suffixBytes.count
  for i in 0..<suffixBytes.count {
    if sBytes[offset + i] != suffixBytes[i] { return false }
  }
  return true
}

public func stringSubstring(_ string: String, from byteOffset: Int) -> String {
  let utf8 = Array(string.utf8)
  guard byteOffset >= 0 && byteOffset < utf8.count else { return "" }
  let slice = utf8[byteOffset...]
  return String(decoding: slice, as: UTF8.self)
}

public func stringSubstring(_ string: String, from start: Int, to end: Int) -> String {
  let utf8 = Array(string.utf8)
  guard start >= 0 && end <= utf8.count && start <= end else { return "" }
  let slice = utf8[start..<end]
  return String(decoding: slice, as: UTF8.self)
}

public func stringContainsCaseInsensitive(_ haystack: String, _ needle: String) -> Bool {
  let nBytes = Array(needle.utf8)
  if nBytes.isEmpty { return true }
  let hBytes = Array(haystack.utf8)
  if nBytes.count > hBytes.count { return false }

  let maxIndex = hBytes.count - nBytes.count

  for i in 0...maxIndex {
    var matches = true
    for j in 0..<nBytes.count {
      let h = hBytes[i + j]
      let n = nBytes[j]

      // ASCII case-insensitive comparison
      // a-z: 97-122. A-Z: 65-90.
      if h != n {
        let hLower = (h >= 65 && h <= 90) ? h + 32 : h
        let nLower = (n >= 65 && n <= 90) ? n + 32 : n
        if hLower != nLower {
          matches = false
          break
        }
      }
    }
    if matches { return true }
  }
  return false
}

public func stringIndexOf(_ haystack: String, _ needle: String) -> Int? {
  let hBytes = Array(haystack.utf8)
  let nBytes = Array(needle.utf8)
  if nBytes.isEmpty { return 0 }
  if nBytes.count > hBytes.count { return nil }

  let maxIndex = hBytes.count - nBytes.count
  for i in 0...maxIndex {
    var matches = true
    for j in 0..<nBytes.count {
      if hBytes[i + j] != nBytes[j] {
        matches = false
        break
      }
    }
    if matches { return i }
  }
  return nil
}

public func stringIndexOfChar(_ string: String, _ char: CChar) -> Int? {
  let target = UInt8(bitPattern: char)
  let utf8 = Array(string.utf8)
  var index = 0
  for byte in utf8 {
    if byte == target {
      return index
    }
    index += 1
  }
  return nil
}

public func stringTrim(_ string: String) -> String {
  let utf8 = Array(string.utf8)
  if utf8.isEmpty { return "" }

  var start = 0
  while start < utf8.count {
    let ch = utf8[start]
    if ch != 32 && ch != 9 && ch != 10 && ch != 13 {
      break
    }
    start += 1
  }

  if start == utf8.count { return "" }

  var end = utf8.count - 1
  while end >= start {
    let ch = utf8[end]
    if ch != 32 && ch != 9 && ch != 10 && ch != 13 {
      break
    }
    end -= 1
  }

  let slice = utf8[start...end]
  return String(decoding: slice, as: UTF8.self)
}

public func isWhitespace(_ char: CChar) -> Bool {
  return char == 32 || char == 9 || char == 10 || char == 13
}

public func stringRepeating(_ string: String, count: Int) -> String {
  if count <= 0 { return "" }
  if count == 1 { return string }
  var buffer = StringBuffer()
  for _ in 0..<count {
    buffer.append(string)
  }
  return buffer.build()
}

public func stringSplit(_ string: String, separator: String) -> [String] {
  let nBytes = Array(separator.utf8)
  if nBytes.isEmpty { return [string] }
  let hBytes = Array(string.utf8)
  var results: [String] = []

  var currentStart = 0
  var i = 0
  let maxI = hBytes.count - nBytes.count

  while i <= maxI {
    var matches = true
    for j in 0..<nBytes.count {
      if hBytes[i + j] != nBytes[j] {
        matches = false
        break
      }
    }

    if matches {
      // Found separator
      if i > currentStart {
        let slice = hBytes[currentStart..<i]
        results.append(String(decoding: slice, as: UTF8.self))
      } else {
        results.append("")
      }
      i += nBytes.count
      currentStart = i
    } else {
      i += 1
    }
  }

  // Add remaining
  if currentStart <= hBytes.count {
    let slice = hBytes[currentStart..<hBytes.count]
    results.append(String(decoding: slice, as: UTF8.self))
  }

  return results
}

public func stringReplace(_ string: String, _ target: String, _ replacement: String) -> String {
  let tBytes = Array(target.utf8)
  if tBytes.isEmpty { return string }
  let hBytes = Array(string.utf8)
  let rBytes = Array(replacement.utf8)
  var result: [UInt8] = []

  var i = 0
  let maxI = hBytes.count - tBytes.count

  while i < hBytes.count {
    var matches = false
    if i <= maxI {
      matches = true
      for j in 0..<tBytes.count {
        if hBytes[i + j] != tBytes[j] {
          matches = false
          break
        }
      }
    }

    if matches {
      // Found target, add replacement
      result.append(contentsOf: rBytes)
      i += tBytes.count
    } else {
      // No match, add current byte
      result.append(hBytes[i])
      i += 1
    }
  }

  return String(decoding: result, as: UTF8.self)
}

public func stringRemovePrefix(_ string: String, _ prefix: String) -> String {
  if stringStartsWith(string, prefix) {
    return stringSubstring(string, from: prefix.utf8.count)
  }
  return string
}

public func stringRemoveSuffix(_ string: String, _ suffix: String) -> String {
  if stringEndsWith(string, suffix) {
    return stringSubstring(string, from: 0, to: string.utf8.count - suffix.utf8.count)
  }
  return string
}

/// Safe integer parsing that avoids Unicode normalization
public func parseInt(_ string: String) -> Int? {
  let utf8 = Array(string.utf8)
  if utf8.isEmpty { return nil }

  var result = 0
  var i = 0
  var isNegative = false

  // Handle optional leading minus
  if utf8[0] == 45 {  // '-'
    isNegative = true
    i = 1
  }

  if i >= utf8.count { return nil }

  while i < utf8.count {
    let byte = utf8[i]
    // Check if it's a digit (0-9 = 48-57)
    if byte >= 48 && byte <= 57 {
      result = result * 10 + Int(byte - 48)
    } else {
      return nil  // Invalid character
    }
    i += 1
  }

  return isNegative ? -result : result
}

/// Convert String to Double without using stdlib strtod (which is unavailable/unstable in Embedded Swift)
public func parseDouble(_ str: String) -> Double? {
  var isNegative = false
  var hasSeenDecimal = false
  var integerPart = 0.0
  var fractionalPart = 0.0
  var divisor = 10.0
  var hasDigits = false
  
  let bytes = Array(str.utf8)
  if bytes.isEmpty { return nil }
  
  var i = 0
  if bytes[0] == 45 { // '-'
    isNegative = true
    i += 1
  } else if bytes[0] == 43 { // '+'
    i += 1
  }
  
  while i < bytes.count {
    let byte = bytes[i]
    if byte == 46 { // '.'
      if hasSeenDecimal { return nil }
      hasSeenDecimal = true
    } else if byte >= 48 && byte <= 57 { // '0' - '9'
      hasDigits = true
      let digit = Double(byte - 48)
      if hasSeenDecimal {
        fractionalPart += digit / divisor
        divisor *= 10.0
      } else {
        integerPart = integerPart * 10.0 + digit
      }
    } else {
      return nil
    }
    i += 1
  }
  
  guard hasDigits else { return nil }
  let value = integerPart + fractionalPart
  return isNegative ? -value : value
}

/// Convert Int to String without Unicode normalization
public func intToString(_ value: Int) -> String {
  return int64ToString(Int64(value))
}

/// Convert Int64 to String without Unicode normalization
public func int64ToString(_ value: Int64, radix: Int = 10, uppercase: Bool = false) -> String {
  if value == 0 { return "0" }

  let isNegative = value < 0
  var num = isNegative ? -value : value
  var digits: [UInt8] = []

  let radix64 = Int64(radix)

  while num > 0 {
    let digit = Int(num % radix64)
    if digit < 10 {
      digits.append(UInt8(48 + digit))  // ASCII '0' is 48
    } else {
      let base: UInt8 = uppercase ? 65 : 97  // 'A' : 'a'
      digits.append(base + UInt8(digit - 10))
    }
    num /= radix64
  }

  if isNegative {
    digits.append(45)  // ASCII '-'
  }

  // Reverse the digits
  var result: [UInt8] = []
  for i in stride(from: digits.count - 1, through: 0, by: -1) {
    result.append(digits[i])
  }

  return String(decoding: result, as: UTF8.self)
}

/// Convert Double to String with high precision (10 places) and trailing zero removal.
/// This prevents microscopic binary noise (e.g. 12.34999...) while preserving user precision.
public func doubleToString(_ value: Double) -> String {
  if value != value { return "0" }

  let isNeg = value < 0
  var val = isNeg ? -value : value

  // Round to 10 decimal places to prune binary noise
  let multiplier = 10000000000.0
  // Manual round for positive val: floor(val * multiplier + 0.5)
  val = Double(Int64(val * multiplier + 0.5)) / multiplier

  let integerPart = Int64(val)
  let fractionalPart = Int64((val - Double(integerPart)) * multiplier + 0.5)

  var res = isNeg ? "-" : ""
  res = "\(res)\(int64ToString(integerPart))"

  if fractionalPart > 0 {
    var fracStr = int64ToString(fractionalPart)

    // Pad with leading zeros up to 10 places
    while fracStr.utf8.count < 10 {
      fracStr = "0\(fracStr)"
    }

    // Convert to array for character removal
    var fracBytes = Array(fracStr.utf8)
    while !fracBytes.isEmpty && fracBytes.last == 48 {  // '0'
      _ = fracBytes.popLast()
    }

    if !fracBytes.isEmpty {
      res = "\(res).\(String(decoding: fracBytes, as: UTF8.self))"
    }
  }

  return res
}

public func stringIsAlphanumeric(_ string: String) -> Bool {
  let bytes = Array(string.utf8)
  if bytes.count != 1 { return false }
  let b = bytes[0]
  return (b >= 97 && b <= 122) || (b >= 65 && b <= 90) || (b >= 48 && b <= 57)
}

public func stringJoin(_ parts: [String], separator: String) -> String {
  if parts.isEmpty { return "" }
  var buffer: [UInt8] = []
  let sepBytes = Array(separator.utf8)

  var j = 0
  for part in parts {
    if j > 0 {
      for b in sepBytes {
        buffer.append(b)
      }
    }
    let pBytes = Array(part.utf8)
    for b in pBytes {
      buffer.append(b)
    }
    j += 1
  }
  return String(decoding: buffer, as: UTF8.self)
}

/// Encode string to base64 (WASM-safe, no Foundation dependency)
public func base64Encode(_ string: String) -> String {
  let input = Array(string.utf8)
  if input.isEmpty { return "" }
  let table: [UInt8] = Array(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
  var result: [UInt8] = []
  var i = 0
  while i + 2 < input.count {
    let b0 = input[i]
    let b1 = input[i + 1]
    let b2 = input[i + 2]
    result.append(table[Int(b0 >> 2)])
    result.append(table[Int((b0 & 0x03) << 4 | b1 >> 4)])
    result.append(table[Int((b1 & 0x0F) << 2 | b2 >> 6)])
    result.append(table[Int(b2 & 0x3F)])
    i += 3
  }
  let remaining = input.count - i
  if remaining == 1 {
    let b0 = input[i]
    result.append(table[Int(b0 >> 2)])
    result.append(table[Int((b0 & 0x03) << 4)])
    result.append(61)  // '='
    result.append(61)
  } else if remaining == 2 {
    let b0 = input[i]
    let b1 = input[i + 1]
    result.append(table[Int(b0 >> 2)])
    result.append(table[Int((b0 & 0x03) << 4 | b1 >> 4)])
    result.append(table[Int((b1 & 0x0F) << 2)])
    result.append(61)  // '='
  }
  return String(decoding: result, as: UTF8.self)
}

/// Decode base64 encoded string to original string (WASM-safe, no Unicode normalization)
public func base64Decode(_ encoded: String) -> String {
  let input = Array(encoded.utf8)
  if input.isEmpty { return "" }
  var bytes: [UInt8] = []
  var buffer: UInt32 = 0
  var bitsCollected = 0
  for byte in input {
    // Stop at padding
    if byte == 61 { break }  // '='
    // Decode base64 character to 6-bit value
    let value: UInt8
    if byte >= 65 && byte <= 90 {  // A-Z
      value = byte - 65
    } else if byte >= 97 && byte <= 122 {  // a-z
      value = byte - 97 + 26
    } else if byte >= 48 && byte <= 57 {  // 0-9
      value = byte - 48 + 52
    } else if byte == 43 {  // +
      value = 62
    } else if byte == 47 {  // /
      value = 63
    } else {
      continue  // Skip invalid characters
    }
    buffer = (buffer << 6) | UInt32(value)
    bitsCollected += 6
    if bitsCollected >= 8 {
      bitsCollected -= 8
      bytes.append(UInt8((buffer >> bitsCollected) & 0xFF))
    }
  }
  return String(decoding: bytes, as: UTF8.self)
}

/// Convert a hex ASCII byte to its numeric value (0-15), or -1 if invalid.
public func hexVal(_ byte: UInt8) -> Int {
  if byte >= 48 && byte <= 57 { return Int(byte - 48) }  // 0-9
  if byte >= 65 && byte <= 70 { return Int(byte - 55) }  // A-F
  if byte >= 97 && byte <= 102 { return Int(byte - 87) }  // a-f
  return -1
}

/// Decodes literal \uXXXX sequences in already-decoded text.
/// Uses manual UTF-8 encoding to avoid Unicode.Scalar (unavailable in Embedded Swift).
/// Handles surrogate pairs (\uD800\uDC00 → single codepoint).
public func decodeUnicodeEscapes(_ text: String) -> String {
  let bytes = Array(text.utf8)
  guard bytes.count >= 6 else { return text }

  var result: [UInt8] = []
  result.reserveCapacity(bytes.count)
  var i = 0
  var hasEscapes = false

  while i < bytes.count {
    // Check for \uXXXX pattern (backslash = 92, u = 117)
    if bytes[i] == 92 && i + 5 < bytes.count && bytes[i + 1] == 117 {
      let h3 = hexVal(bytes[i + 2])
      let h2 = hexVal(bytes[i + 3])
      let h1 = hexVal(bytes[i + 4])
      let h0 = hexVal(bytes[i + 5])
      if h3 >= 0 && h2 >= 0 && h1 >= 0 && h0 >= 0 {
        var codepoint = UInt32(h3) << 12 | UInt32(h2) << 8 | UInt32(h1) << 4 | UInt32(h0)

        // Handle surrogate pairs: \uD800-\uDBFF followed by \uDC00-\uDFFF
        var consumedExtra = 0
        if codepoint >= 0xD800 && codepoint <= 0xDBFF && i + 11 < bytes.count
          && bytes[i + 6] == 92 && bytes[i + 7] == 117
        {
          let l3 = hexVal(bytes[i + 8])
          let l2 = hexVal(bytes[i + 9])
          let l1 = hexVal(bytes[i + 10])
          let l0 = hexVal(bytes[i + 11])
          if l3 >= 0 && l2 >= 0 && l1 >= 0 && l0 >= 0 {
            let low = UInt32(l3) << 12 | UInt32(l2) << 8 | UInt32(l1) << 4 | UInt32(l0)
            if low >= 0xDC00 && low <= 0xDFFF {
              codepoint = 0x10000 + (codepoint - 0xD800) * 0x400 + (low - 0xDC00)
              consumedExtra = 6
            }
          }
        }

        // Skip lone surrogates
        if codepoint >= 0xD800 && codepoint <= 0xDFFF {
          result.append(bytes[i])
          i += 1
          continue
        }

        // Manual UTF-8 encode
        if codepoint <= 0x7F {
          result.append(UInt8(codepoint))
        } else if codepoint <= 0x7FF {
          result.append(UInt8(0xC0 | (codepoint >> 6)))
          result.append(UInt8(0x80 | (codepoint & 0x3F)))
        } else if codepoint <= 0xFFFF {
          result.append(UInt8(0xE0 | (codepoint >> 12)))
          result.append(UInt8(0x80 | ((codepoint >> 6) & 0x3F)))
          result.append(UInt8(0x80 | (codepoint & 0x3F)))
        } else if codepoint <= 0x10FFFF {
          result.append(UInt8(0xF0 | (codepoint >> 18)))
          result.append(UInt8(0x80 | ((codepoint >> 12) & 0x3F)))
          result.append(UInt8(0x80 | ((codepoint >> 6) & 0x3F)))
          result.append(UInt8(0x80 | (codepoint & 0x3F)))
        }
        hasEscapes = true
        i += 6 + consumedExtra
        continue
      }
    }
    result.append(bytes[i])
    i += 1
  }

  guard hasEscapes else { return text }
  return String(decoding: result, as: UTF8.self)
}
