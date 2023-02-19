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

  @StateObject private var safariManager = InAppSafariManager()
  
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
          return safariManager.open(url)
        }
      }
      .background {
        WindowReader { window in
          self.safariManager.windowScene = window.windowScene
        }
      }
  }
}

private class InAppSafariManager: NSObject, ObservableObject, SFSafariViewControllerDelegate {
  var windowScene: UIWindowScene?
  let viewController: UIViewController = UIViewController()
  var window: UIWindow?

  @MainActor
  func open(_ url: URL) -> OpenURLAction.Result {
    guard let windowScene = windowScene else { return .systemAction }
    
    self.window = setupWindow(windowScene: windowScene)
    
    let configuration = SFSafariViewController.Configuration()
    configuration.entersReaderIfAvailable = UserPreferences.shared.inAppBrowserReaderView
    
    let safari = SFSafariViewController(url: url, configuration: configuration)
    safari.preferredBarTintColor = UIColor(Theme.shared.primaryBackgroundColor)
    safari.preferredControlTintColor = UIColor(Theme.shared.tintColor)
    safari.delegate = self
    
    DispatchQueue.main.async { [weak self] in
      self?.viewController.present(safari, animated: true)
    }
    
    return .handled
  }

  func setupWindow(windowScene: UIWindowScene) -> UIWindow {
    let window = self.window ?? UIWindow(windowScene: windowScene)
    
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    
    switch Theme.shared.selectedScheme {
    case .dark:
      window.overrideUserInterfaceStyle = .dark
    case .light:
      window.overrideUserInterfaceStyle = .light
    }
    
    self.window = window
    return window
  }

  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    window?.resignKey()
    window?.isHidden = false
    window = nil
  }
}

private struct WindowReader: UIViewRepresentable {
  var onUpdate: (UIWindow) -> Void

  func makeUIView(context: Context) -> InjectView {
    InjectView(onUpdate: onUpdate)
  }

  func updateUIView(_ uiView: InjectView, context: Context) {
  }

  class InjectView: UIView {
    var onUpdate: (UIWindow) -> Void
    
    init(onUpdate: @escaping (UIWindow) -> Void) {
      self.onUpdate = onUpdate
      super.init(frame: .zero)
      isHidden = true
      isUserInteractionEnabled = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
      super.willMove(toWindow: newWindow)
        
      if let window = newWindow {
        onUpdate(window)
      } else {
        DispatchQueue.main.async { [weak self] in
          if let window = self?.window {
            self?.onUpdate(window)
          }
        }
      }
    }
  }
}
