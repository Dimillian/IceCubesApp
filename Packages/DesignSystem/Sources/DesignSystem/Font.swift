import Env
import SwiftUI

@MainActor
public extension Font {
  static func userScaledFontSize(baseSize: CGFloat) -> CGFloat {
    UIFontMetrics.default.scaledValue(for: baseSize * UserPreferences.shared.fontSizeScale)
  }

  static var scaledTitle: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 28))
    } else {
      return .title
    }
  }

  static var scaledHeadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 20), weight: .semibold)
    } else {
      return .headline
    }
  }

  static var scaledBody: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 19))
    } else {
      return .body
    }
  }

  static var scaledBodyUIFont: UIFont {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return UIFont.systemFont(ofSize: userScaledFontSize(baseSize: 19))
    } else {
      return UIFont.systemFont(ofSize: 17)
    }
  }

  static var scaledCallout: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 17))
    } else {
      return .callout
    }
  }

  static var scaledSubheadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 16))
    } else {
      return .subheadline
    }
  }

  static var scaledFootnote: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 15))
    } else {
      return .footnote
    }
  }

  static var scaledCaption: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 14))
    } else {
      return .caption
    }
  }
}
