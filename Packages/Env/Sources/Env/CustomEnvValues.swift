import Foundation
import SwiftUI

private struct SecondaryColumnKey: EnvironmentKey {
  static let defaultValue = false
}

public extension EnvironmentValues {
  var isSecondaryColumn: Bool {
    get { self[SecondaryColumnKey.self] }
    set { self[SecondaryColumnKey.self] = newValue }
  }
}
