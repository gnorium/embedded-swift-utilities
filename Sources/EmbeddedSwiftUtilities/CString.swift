#if os(WASI)

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

public func stringEquals(_ lhs: String, _ rhs: String) -> Bool {
    return lhs.utf8.elementsEqual(rhs.utf8)
}

public func stringEquals(_ string: String, _ staticString: StaticString) -> Bool {
    return staticString.withUTF8Buffer { buffer in
        string.utf8.elementsEqual(buffer)
    }
}

public func stringContains(_ haystack: String, _ needle: String) -> Bool {
    return stringIndexOf(haystack, needle) != nil
}

public func stringStartsWith(_ string: String, _ prefix: StaticString) -> Bool {
    return prefix.withUTF8Buffer { buffer in
        string.utf8.starts(with: buffer)
    }
}

public func stringStartsWith(_ string: String, _ prefix: String) -> Bool {
    return string.utf8.starts(with: prefix.utf8)
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
    for (index, byte) in utf8.enumerated() {
        if byte == target {
            return index
        }
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

/// Safe integer parsing that avoids Unicode normalization
public func safeParseInt(_ string: String) -> Int? {
	let utf8 = Array(string.utf8)
	if utf8.isEmpty { return nil }
	
	var result = 0
	var i = 0
	var isNegative = false
	
	// Handle optional leading minus
	if utf8[0] == 45 { // '-'
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
			return nil // Invalid character
		}
		i += 1
	}
	
	return isNegative ? -result : result
}

/// Convert Int to String without Unicode normalization
public func intToString(_ value: Int) -> String {
	if value == 0 { return "0" }

	let isNegative = value < 0
	var num = isNegative ? -value : value
	var digits: [UInt8] = []

	while num > 0 {
		let digit = num % 10
		digits.append(UInt8(48 + digit)) // ASCII '0' is 48
		num /= 10
	}

	if isNegative {
		digits.append(45) // ASCII '-'
	}

	// Reverse the digits
	var result: [UInt8] = []
	for i in stride(from: digits.count - 1, through: 0, by: -1) {
		result.append(digits[i])
	}

	return String(decoding: result, as: UTF8.self)
}

/// Convert Double to String without Unicode normalization (simplified)
public func doubleToString(_ value: Double) -> String {
    // Robustness: handle NaN and Inf (simple check)
    if value != value { return "0.000" }
    // Hard limit to avoid Int overflow crashes
    if value > 2000000.0 || value < -2000000.0 { return "0.000" }

    let intV = Int(value * 1000.0)
    let isNeg = intV < 0
    let absV = isNeg ? -intV : intV
    
    let s = intToString(absV)
    var res: [UInt8] = []
    if isNeg { res.append(45) } // '-'
    
    let bytes = Array(s.utf8)
    if bytes.count <= 3 {
        res.append(48) // '0'
        res.append(46) // '.'
        if bytes.count < 3 {
            for _ in 0..<(3 - bytes.count) {
                res.append(48) // '0'
            }
        }
        res.append(contentsOf: bytes)
    } else {
        let splitAt = bytes.count - 3
        res.append(contentsOf: bytes[0..<splitAt])
        res.append(46) // '.'
        res.append(contentsOf: bytes[splitAt...])
    }
    return String(decoding: res, as: UTF8.self)
}


public func stringConcat(_ parts: String...) -> String {
	var buffer: [UInt8] = []
	for part in parts {
		buffer.append(contentsOf: part.utf8)
	}
	return String(decoding: buffer, as: UTF8.self)
}

public func stringJoin(_ parts: [String], separator: String) -> String {
	if parts.isEmpty { return "" }
	var buffer: [UInt8] = []
	let sepBytes = Array(separator.utf8)
	
	for (index, part) in parts.enumerated() {
		if index > 0 {
			buffer.append(contentsOf: sepBytes)
		}
		buffer.append(contentsOf: part.utf8)
	}
	return String(decoding: buffer, as: UTF8.self)
}

#endif
