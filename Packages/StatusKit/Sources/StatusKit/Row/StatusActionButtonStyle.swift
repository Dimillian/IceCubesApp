import DesignSystem
import SwiftUI
import UIKit

extension ButtonStyle where Self == StatusActionButtonStyle {
  static func statusAction(isOn: Bool = false, tintColor: Color? = nil) -> Self {
    StatusActionButtonStyle(isOn: isOn, tintColor: tintColor)
  }
}

/// A toggle button that slightly scales and changes its foreground color to `tintColor` when toggled on
struct StatusActionButtonStyle: ButtonStyle {
  var isOn: Bool
  var tintColor: Color?

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(isOn ? tintColor : Color(UIColor.secondaryLabel))
      .animation(nil, value: isOn)
      .brightness(brightness(configuration: configuration))
      .animation(configuration.isPressed ? nil : .default, value: isOn)
      .scaleEffect(configuration.isPressed && !isOn ? 0.8 : 1.0)
  }

  func brightness(configuration: Configuration) -> Double {
    switch (configuration.isPressed, isOn) {
    case (true, true): 0.6
    case (true, false): 0.2
    default: 0
    }
  }
}
