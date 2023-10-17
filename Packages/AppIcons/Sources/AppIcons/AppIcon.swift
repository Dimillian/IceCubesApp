import Foundation

public enum AppIcon: Int, Identifiable, CaseIterable {
    public var id: String { String(self.rawValue) }

    case primary = 0
    case alt1, alt2, alt3, alt4, alt5, alt6, alt7, alt8
    case alt9, alt10, alt11, alt12, alt13, alt14
    case alt15, alt16, alt17, alt18, alt19, alt20, alt21
    case alt22, alt23, alt24, alt25
    case alt26, alt27, alt28
    case alt29, alt30, alt31, alt32
    case alt33
    case alt34, alt35
    case alt36
    case alt37
    case alt38, alt39
    case alt40, alt41, alt42

    public init(string: String) {
        if string == AppIcon.primary.appIconName {
            self = AppIcon.primary
        } else {
            self = .init(rawValue: Int(String(string.replacing("AppIconAlternate", with: "")))!)!
        }
    }

    /// File name for the actual App Icon asset.
    var appIconName: String {
        switch self {
            case .primary:  "AppIcon"
            default:        "AppIconAlternate\(rawValue)"
        }
    }

    /// Small, preview-sized render of the app icon.
    var iconName: String {
        "icon\(rawValue)"
    }
}
