import SwiftUI
import SafariServices
import Env
import DesignSystem

extension View {
    func withSafariRouteur() -> some View {
        modifier(SafariRouteur())
    }
}

private struct SafariRouteur: ViewModifier {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var routeurPath: RouterPath
    
    @State private var safari: SFSafariViewController?
    
    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
              routeurPath.handle(url: url)
            })
            .onAppear {
                routeurPath.urlHandler = { url in
                    guard preferences.preferredBrowser == .inAppSafari else { return .systemAction }
                    // SFSafariViewController only supports initial URLs with http:// or https:// schemes.
                    guard let scheme = url.scheme, ["https", "http"].contains(scheme.lowercased()) else {
                        return .systemAction
                    }
                    
                    let safari = SFSafariViewController(url: url)
                    safari.preferredBarTintColor = UIColor(theme.primaryBackgroundColor)
                    safari.preferredControlTintColor = UIColor(theme.tintColor)
                    
                    self.safari = safari
                    return .handled
                }
            }
            .background {
                SafariPresenter(safari: safari)
            }
    }
    
    struct SafariPresenter: UIViewRepresentable {
        var safari: SFSafariViewController?
        
        func makeUIView(context: Context) -> UIView {
            let view = UIView(frame: .zero)
            view.isHidden = true
            view.isUserInteractionEnabled = false
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            guard let safari = safari, let viewController = uiView.findTopViewController() else { return }
            viewController.present(safari, animated: true)
        }
    }
}

private extension UIView {
    func findTopViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder.topViewController()
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findTopViewController()
        } else {
            return nil
        }
    }
}

private extension UIViewController {
    func topViewController() -> UIViewController? {
        if let nvc = self as? UINavigationController {
            return nvc.visibleViewController?.topViewController()
        } else if let tbc = self as? UITabBarController, let selected = tbc.selectedViewController {
            return selected.topViewController()
        } else if let presented = self.presentedViewController {
            return presented.topViewController()
        }
        return self
    }
}
