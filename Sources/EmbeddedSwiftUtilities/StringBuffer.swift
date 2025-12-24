// Manual string building for embedded Swift to avoid Unicode normalization

#if os(WASI)
/// Builds strings from parts without triggering Unicode normalization
public struct StringBuffer {
    private var buffer: [UInt8] = []

    public init() {}

    public mutating func append(_ staticString: StaticString) {
        staticString.withUTF8Buffer { buf in
            buffer.append(contentsOf: buf)
        }
    }

    public mutating func append(_ string: String) {
        buffer.append(contentsOf: string.utf8)
    }

    public func build() -> String {
        String(decoding: buffer, as: UTF8.self)
    }
}

/// Build a string from static and dynamic parts without interpolation
public func buildString(_ parts: (inout StringBuffer) -> Void) -> String {
    var buffer = StringBuffer()
    parts(&buffer)
    return buffer.build()
}
#endif
