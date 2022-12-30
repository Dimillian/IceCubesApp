import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
    case colorScheme, tint, label, primaryBackground, secondaryBackground
  }
  
  @AppStorage(ThemeKey.colorScheme.rawValue) public var colorScheme: String = "dark"
  @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .brand
  @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .primaryBackground
  @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .secondaryBackground
  
  public init() { }
}
