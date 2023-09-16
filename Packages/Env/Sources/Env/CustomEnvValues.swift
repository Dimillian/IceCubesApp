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

private struct IsInCaptureMode: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsSupporter: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsStatusDetailLoaded: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsStatusFocused: EnvironmentKey {
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

  var isInCaptureMode: Bool {
    get { self[IsInCaptureMode.self] }
    set { self[IsInCaptureMode.self] = newValue }
  }

  var isSupporter: Bool {
    get { self[IsSupporter.self] }
    set { self[IsSupporter.self] = newValue }
  }
  
  var isStatusDetailLoaded: Bool {
    get { self[IsStatusDetailLoaded.self] }
    set { self[IsStatusDetailLoaded.self] = newValue }
  }
  
  var isStatusFocused: Bool {
    get { self[IsStatusFocused.self] }
    set { self[IsStatusFocused.self] = newValue }
  }
}
