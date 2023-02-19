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

  @State private var presentedURL: URL?

  func body(content: Content) -> some View {
    content
      .environment(\.openURL, OpenURLAction { url in
        // Open internal URL.
        routerPath.handle(url: url)
      })
      .onOpenURL { url in
        // Open external URL (from icecubesapp://)
        let urlString = url.absoluteString.replacingOccurrences(of: "icecubesapp://", with: "https://")
        guard let url = URL(string: urlString), url.host != nil else { return }
        _ = routerPath.handle(url: url)
      }
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

          presentedURL = url
          return .handled
        }
      }
      .background {
        SafariPresenter(url: $presentedURL)
          .frame(width: 0, height: 0)
      }
  }
}

struct SafariPresenter: UIViewControllerRepresentable {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var routerPath: RouterPath
  @Binding var url: URL?

  func makeUIViewController(context _: Context) -> UIViewController {
    let view = UIView(frame: .zero)
    view.isHidden = true
    view.isUserInteractionEnabled = false
    let viewController = UIViewController()
    viewController.view = view
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    defer { url = nil }
    guard let url = url, let viewController = uiViewController.topViewController() else { return }
    let configuration = SFSafariViewController.Configuration()
    configuration.entersReaderIfAvailable = preferences.inAppBrowserReaderView

    let safari = SFSafariViewController(url: url, configuration: configuration)
    safari.preferredBarTintColor = UIColor(theme.primaryBackgroundColor)
    safari.preferredControlTintColor = UIColor(theme.tintColor)
    safari.delegate = context.coordinator
    viewController.present(safari, animated: true) {
      routerPath.isSafariPresented = true
    }
  }
    
  func makeCoordinator() -> Coordinator {
    Coordinator(routerPath: routerPath)
  }

  class Coordinator: NSObject, SFSafariViewControllerDelegate {
    weak var routerPath: RouterPath?
      
    init(routerPath: RouterPath?) {
      self.routerPath = routerPath
    }

    @MainActor
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
      routerPath?.isSafariPresented = false
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
