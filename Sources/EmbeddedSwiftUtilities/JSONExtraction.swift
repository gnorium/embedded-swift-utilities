// JSON extraction utilities for Embedded Swift (WASM)
// Simple byte-based parsing without Foundation

#if os(WASI)

/// Extract a string value for a given key from a JSON string
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
			if byte == 34 && !prevWasBackslash { // 34 = '"'
				break
			}
			prevWasBackslash = (byte == 92) // 92 = '\'
			endIndex += 1
		}

		guard endIndex > startIndex && endIndex < jsonBytes.count else { return nil }

		// Extract value
		let valueBytes = Array(jsonBytes[startIndex..<endIndex])
		return String(decoding: valueBytes, as: UTF8.self)
	} ?? nil
}

#endif
