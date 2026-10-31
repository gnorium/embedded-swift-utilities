/// A list as English prose writes it, with the Oxford comma: "A", "A and B",
/// "A, B, and C".
public enum EnglishList {
  /// The items joined: "A, B, and C".
  public static func joined(_ items: [String]) -> String {
    var out = ""
    for (index, item) in items.enumerated() {
      out += separator(before: index, of: items.count) + item
    }
    return out
  }

  /// What goes before the item at `index` in a list of `count`: nothing
  /// before the first, " and " between two, ", " inside a longer list, and
  /// ", and " before its last.
  public static func separator(before index: Int, of count: Int) -> String {
    if index == 0 { return "" }
    if count == 2 { return " and " }
    return index == count - 1 ? ", and " : ", "
  }
}
