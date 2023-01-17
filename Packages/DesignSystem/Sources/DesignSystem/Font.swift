import SwiftUI

extension Font {
  public static var scaledTitle: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 28))
    } else {
      return .title
    }
  }
  
  public static var scaledHeadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 19), weight: .semibold)
    } else {
      return .headline
    }
  }
    
  public static var scaledBody: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 19))
    } else {
      return .body
    }
  }
  
  public static var scaledCallout: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 17))
    } else {
      return .callout
    }
  }
  
  public static var scaledSubheadline: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 16))
    } else {
      return .subheadline
    }
  }
  
  
  public static var scaledFootnote: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 15))
    } else {
      return .footnote
    }
  }
  
  public static var scaledCaption: Font {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      return .system(size: UIFontMetrics.default.scaledValue(for: 14))
    } else {
      return .caption
    }
  }
}
