import DesignSystem
import Env
import SafariServices
import SwiftUI

extension View {
  func withSafariRouter() -> some View {
    modifier(SafariRouter())
  }
}

private struct SafariRouter: ViewModifier {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var routerPath: RouterPath

  @State private var safari: SFSafariViewController?

  func body(content: Content) -> some View {
    content
      .environment(\.openURL, OpenURLAction { url in
        // Open internal URL.
        routerPath.handle(url: url)
      })
      .onOpenURL(perform: { url in
        // Open external URL (from icecubesapp://)
        let urlString = url.absoluteString.replacingOccurrences(of: "icecubesapp://", with: "https://")
        guard let url = URL(string: urlString), url.host != nil else { return }
        _ = routerPath.handle(url: url)
      })
      .onAppear {
        routerPath.urlHandler = { url in
          if url.absoluteString.contains("@twitter.com"), url.absoluteString.hasPrefix("mailto:") {
            let username = url.absoluteString
              .replacingOccurrences(of: "@twitter.com", with: "")
              .replacingOccurrences(of: "mailto:", with: "")
            let twitterLink = "https://twitter.com/\(username)"
            if let url = URL(string: twitterLink) {
              UIApplication.shared.open(url)
              return .handled
            }
          }
          guard preferences.preferredBrowser == .inAppSafari, !ProcessInfo.processInfo.isiOSAppOnMac else { return .systemAction }
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

    func makeUIView(context _: Context) -> UIView {
      let view = UIView(frame: .zero)
      view.isHidden = true
      view.isUserInteractionEnabled = false
      return view
    }

    func updateUIView(_ uiView: UIView, context _: Context) {
      guard let safari = safari, let viewController = uiView.findTopViewController() else { return }
      viewController.present(safari, animated: true)
    }
  }
}

private extension UIView {
  func findTopViewController() -> UIViewController? {
    if let nextResponder = next as? UIViewController {
      return nextResponder.topViewController()
    } else if let nextResponder = next as? UIView {
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
    } else if let presented = presentedViewController {
      return presented.topViewController()
    }
    return self
  }
}
