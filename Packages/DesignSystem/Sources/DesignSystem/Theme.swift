import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
    case tint, label, primaryBackground, secondaryBackground
  }
  
  @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .brand
  @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .primaryBackground
  @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .secondaryBackground
  @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .label
  
  public init() { }
}
