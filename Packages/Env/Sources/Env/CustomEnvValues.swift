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

private struct IsMediaCompact: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsModal: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsInCaptureMode: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsSupporter: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsStatusFocused: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IsHomeTimeline: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IndentationLevel: EnvironmentKey {
  static let defaultValue: UInt = 0
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

  var isMediaCompact: Bool {
    get { self[IsMediaCompact.self] }
    set { self[IsMediaCompact.self] = newValue }
  }

  var isModal: Bool {
    get { self[IsModal.self] }
    set { self[IsModal.self] = newValue }
  }

  var isInCaptureMode: Bool {
    get { self[IsInCaptureMode.self] }
    set { self[IsInCaptureMode.self] = newValue }
  }

  var isSupporter: Bool {
    get { self[IsSupporter.self] }
    set { self[IsSupporter.self] = newValue }
  }

  var isStatusFocused: Bool {
    get { self[IsStatusFocused.self] }
    set { self[IsStatusFocused.self] = newValue }
  }

  var indentationLevel: UInt {
    get { self[IndentationLevel.self] }
    set { self[IndentationLevel.self] = newValue }
  }

  var isHomeTimeline: Bool {
    get { self[IsHomeTimeline.self] }
    set { self[IsHomeTimeline.self] = newValue }
  }
}
