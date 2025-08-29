import Foundation
import SwiftUI

extension EnvironmentValues {
  @Entry public var isSecondaryColumn: Bool = false
  @Entry public var extraLeadingInset: CGFloat = 0
  @Entry public var isCompact: Bool = false
  @Entry public var isMediaCompact: Bool = false
  @Entry public var isCatalystWindow: Bool = false
  @Entry public var isModal: Bool = false
  @Entry public var isInCaptureMode: Bool = false
  @Entry public var isSupporter: Bool = false
  @Entry public var isStatusFocused: Bool = false
  @Entry public var isHomeTimeline: Bool = false
  @Entry public var indentationLevel: UInt = 0
  @Entry public var selectedTabScrollToTop: Int = -1
  // Set to true when rendering inside the Notifications tab
  @Entry public var isNotificationsTab: Bool = false
}
