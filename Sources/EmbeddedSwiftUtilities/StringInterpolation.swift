#if os(WASI)

extension String.StringInterpolation {
	public mutating func appendInterpolation(_ value: Int) {
		var num = value
		let isNegative = num < 0
		if isNegative {
			num = -num
		}

		var digits: [UInt8] = []
		if num == 0 {
			digits.append(48) // '0'
		} else {
			while num > 0 {
				let digit = num % 10
				digits.append(48 + UInt8(digit))
				num /= 10
			}
		}

		if isNegative {
			appendLiteral("-")
		}
		
		// Digits are reversed
		var resultBytes: [UInt8] = []
		for byte in digits.reversed() {
			resultBytes.append(byte)
		}
		appendLiteral(String(decoding: resultBytes, as: UTF8.self))
	}

	public mutating func appendInterpolation(_ value: Double) {
		var num = Int(value)
		let isNegative = value < 0
		if isNegative {
			num = -num
		}

		var digits: [UInt8] = []
		if num == 0 {
			digits.append(48) // '0'
		} else {
			while num > 0 {
				let digit = num % 10
				digits.append(48 + UInt8(digit))
				num /= 10
			}
		}

		if isNegative {
			appendLiteral("-")
		}
		
		var resultBytes: [UInt8] = []
		for byte in digits.reversed() {
			resultBytes.append(byte)
		}
		appendLiteral(String(decoding: resultBytes, as: UTF8.self))

		let fracPart = value - Double(Int(value))
		if fracPart != 0 {
			appendLiteral(".")
			var frac = abs(fracPart)
			// Continue until we hit floating point precision limit
			var fracBytes: [UInt8] = []
			while frac > 0.0000000000000001 {
				frac *= 10
				let digit = Int(frac)
				fracBytes.append(48 + UInt8(digit))
				frac -= Double(digit)
			}
			appendLiteral(String(decoding: fracBytes, as: UTF8.self))
		}
	}

	public mutating func appendInterpolation(_ value: String) {
		appendLiteral(value)
	}

	public mutating func appendInterpolation(_ value: StaticString) {
		value.withUTF8Buffer { buffer in
			let str = String(decoding: buffer, as: UTF8.self)
			appendLiteral(str)
		}
	}

	public mutating func appendInterpolation(_ value: Bool) {
		appendLiteral(value ? "true" : "false")
	}
}

extension String {
	public mutating func append(_ value: Int) {
		var num = value
		let isNegative = num < 0
		if isNegative {
			num = -num
		}

		var digits: [UInt8] = []
		if num == 0 {
			digits.append(48) // '0'
		} else {
			while num > 0 {
				let digit = num % 10
				digits.append(48 + UInt8(digit))
				num /= 10
			}
		}

		if isNegative {
			self.append("-")
		}
		
		var resultBytes: [UInt8] = []
		for byte in digits.reversed() {
			resultBytes.append(byte)
		}
		self.append(String(decoding: resultBytes, as: UTF8.self))
	}

	public mutating func append(_ value: Double) {
		let intPart = Int(value)
		self.append(intPart)

		let fracPart = value - Double(intPart)
		if fracPart != 0 {
			self.append(".")
			var frac = abs(fracPart)
			// Continue until we hit floating point precision limit
			var fracBytes: [UInt8] = []
			while frac > 0.0000000000000001 {
				frac *= 10
				let digit = Int(frac)
				fracBytes.append(48 + UInt8(digit))
				frac -= Double(digit)
			}
			self.append(String(decoding: fracBytes, as: UTF8.self))
		}
	}

	public mutating func append(_ value: Bool) {
		self.append(value ? "true" : "false")
	}
}

#endif
