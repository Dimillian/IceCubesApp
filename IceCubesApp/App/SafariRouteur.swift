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
                    guard preferences.useInAppSafari else { return .systemAction }
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
                Presenter(safari: safari)
            }
    }
    
    struct Presenter: UIViewControllerRepresentable {
        var safari: SFSafariViewController?
        
        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            viewController.view = UIView(frame: .zero)
            viewController.view.isUserInteractionEnabled = false
            return viewController
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            guard let safari = safari else { return }
            uiViewController.present(safari, animated: true)
        }
    }
}
