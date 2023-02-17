import Foundation
import SwiftUI

private struct SecondaryColumnKey: EnvironmentKey {
  static let defaultValue = false
}

private struct ExtraLeadingInset: EnvironmentKey {
  static let defaultValue: CGFloat = 0
}

private struct IsCompact: EnvironmentKey {
  static let defaultValue: Bool = false
}

public extension EnvironmentValues {
  var isSecondaryColumn: Bool {
    get { self[SecondaryColumnKey.self] }
    set { self[SecondaryColumnKey.self] = newValue }
  }
  
  var extraLeadingInset: CGFloat {
    get { self[ExtraLeadingInset.self] }
    set { self[ExtraLeadingInset.self] = newValue }
  }
  
  var isCompact: Bool {
    get { self[IsCompact.self] }
    set { self[IsCompact.self] = newValue }
  }
}
