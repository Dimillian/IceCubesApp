import Env
import SwiftUI

@MainActor
public extension Font {
  // See https://gist.github.com/zacwest/916d31da5d03405809c4 for iOS values
  // Custom values for Mac
  private static let title = 28.0
  private static let headline = onMac ? 20.0 : 17.0
  private static let body = onMac ? 19.0 : 17.0
  private static let callout = onMac ? 17.0 : 16.0
  private static let subheadline = onMac ? 16.0 : 15.0
  private static let footnote = onMac ? 15.0 : 13.0
  private static let caption = onMac ? 14.0 : 12.0
  private static let onMac = ProcessInfo.processInfo.isiOSAppOnMac

  private static func customFont(size: CGFloat, relativeTo textStyle: TextStyle) -> Font {
    if let chosenFont = UserPreferences.shared.chosenFont {
      return .custom(chosenFont.fontName, size: size, relativeTo: textStyle)
    }

    return .system(size: size)
  }

  private static func customUIFont(size: CGFloat) -> UIFont {
    if let chosenFont = UserPreferences.shared.chosenFont {
      return chosenFont.withSize(size)
    }

    return .systemFont(ofSize: size)
  }

  private static func userScaledFontSize(baseSize: CGFloat) -> CGFloat {
    UIFontMetrics.default.scaledValue(for: baseSize * UserPreferences.shared.fontSizeScale)
  }

  static var scaledTitle: Font {
    customFont(size: userScaledFontSize(baseSize: title), relativeTo: .title)
  }

  static var scaledHeadline: Font {
    customFont(size: userScaledFontSize(baseSize: headline), relativeTo: .headline).weight(.semibold)
  }

  static var scaledBody: Font {
    customFont(size: userScaledFontSize(baseSize: body), relativeTo: .body)
  }

  static var scaledBodyUIFont: UIFont {
    customUIFont(size: userScaledFontSize(baseSize: body))
  }

  static var scaledCallout: Font {
    customFont(size: userScaledFontSize(baseSize: callout), relativeTo: .callout)
  }

  static var scaledSubheadline: Font {
    customFont(size: userScaledFontSize(baseSize: subheadline), relativeTo: .subheadline)
  }

  static var scaledFootnote: Font {
    customFont(size: userScaledFontSize(baseSize: footnote), relativeTo: .footnote)
  }

  static var scaledCaption: Font {
    customFont(size: userScaledFontSize(baseSize: caption), relativeTo: .caption)
  }
}
