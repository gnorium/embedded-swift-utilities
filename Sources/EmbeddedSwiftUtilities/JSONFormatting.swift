/// Escapes a string for inclusion in a JSON string value.
/// Handles ALL JSON-required escapes: backslash, quote, and all control characters (U+0000–U+001F).
public func jsonEscapeString(_ str: String) -> String {
  let bytes = Array(str.utf8)
  var result: [UInt8] = []
  for byte in bytes {
    switch byte {
    case 0x5C:
      result.append(0x5C)
      result.append(0x5C)  // \ → \\
    case 0x22:
      result.append(0x5C)
      result.append(0x22)  // " → \"
    case 0x0A:
      result.append(0x5C)
      result.append(0x6E)  // newline → \n
    case 0x0D:
      result.append(0x5C)
      result.append(0x72)  // CR → \r
    case 0x09:
      result.append(0x5C)
      result.append(0x74)  // tab → \t
    case 0x08:
      result.append(0x5C)
      result.append(0x62)  // backspace → \b
    case 0x0C:
      result.append(0x5C)
      result.append(0x66)  // form feed → \f
    case 0x00...0x1F:
      // Other control chars → \u00XX
      result.append(0x5C)  // \
      result.append(0x75)  // u
      result.append(0x30)  // 0
      result.append(0x30)  // 0
      let hi = byte >> 4
      let lo = byte & 0x0F
      result.append(hi < 10 ? 0x30 + hi : 0x61 + hi - 10)
      result.append(lo < 10 ? 0x30 + lo : 0x61 + lo - 10)
    default:
      result.append(byte)
    }
  }
  return String(decoding: result, as: UTF8.self)
}
