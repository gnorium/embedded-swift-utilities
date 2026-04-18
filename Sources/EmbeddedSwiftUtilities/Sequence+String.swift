// Foundation-level extensions to resolve standard library ambiguities in Embedded Swift.

extension Sequence where Element == String {
    /// An unambiguous join operation for Embedded Swift environments.
    /// Uses StringBuffer for memory-efficient concatenation.
    @inlinable
    public func joinedString(separator: String = "") -> String {
        var result = StringBuffer()
        for (index, element) in self.enumerated() {
            if index > 0 { result.append(separator) }
            result.append(element)
        }
        return result.build()
    }
}
