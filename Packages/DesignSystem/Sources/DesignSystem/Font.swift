import SwiftUI
import Env

@MainActor
extension Font {
  
  public static func userScaledFontSize(baseSize: CGFloat) -> CGFloat {
    UIFontMetrics.default.scaledValue(for: baseSize * UserPreferences.shared.fontSizeScale)
  }
  
  public static var scaledTitle: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 28))
    } else {
      return .title
    }
  }
  
  public static var scaledHeadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 20), weight: .semibold)
    } else {
      return .headline
    }
  }
    
  public static var scaledBody: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 19))
    } else {
      return .body
    }
  }
  
  public static var scaledCallout: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 17))
    } else {
      return .callout
    }
  }
  
  public static var scaledSubheadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 16))
    } else {
      return .subheadline
    }
  }
  
  
  public static var scaledFootnote: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 15))
    } else {
      return .footnote
    }
  }
  
  public static var scaledCaption: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: userScaledFontSize(baseSize: 14))
    } else {
      return .caption
    }
  }
}
