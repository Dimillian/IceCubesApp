import SwiftUI
import Observation

@Observable
public class IconController {
    public private(set) var currentIcon: String = UIApplication.shared.alternateIconName ?? AppIcon.primary.appIconName

    private init() {
    }

    public static let shared = IconController()

    public func setAppIcon(_ newAppIcon: AppIcon) {
        switch newAppIcon {
            case .primary:
                UIApplication.shared.setAlternateIconName(nil)
            default:
                UIApplication.shared.setAlternateIconName(newAppIcon.appIconName) { error in
                    if let error {
                        print("\(error.localizedDescription) – Icon Name: \(newAppIcon.iconName)")
                    }
                }
        }

        currentIcon = UIApplication.shared.alternateIconName ?? AppIcon.primary.appIconName
    }
}

struct IconControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: IconController = IconController.shared
}

public extension EnvironmentValues {
    var iconController: IconController {
        get { self[IconControllerEnvironmentKey.self] }
        set { self[IconControllerEnvironmentKey.self] = newValue }
    }
}
