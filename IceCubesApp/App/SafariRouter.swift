import DesignSystem
import Env
import Models
import Observation
import SafariServices
import SwiftUI

extension View {
  @MainActor func withSafariRouter() -> some View {
    modifier(SafariRouter())
  }
}

@MainActor
private struct SafariRouter: ViewModifier {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var preferences
  @Environment(RouterPath.self) private var routerPath

  @State private var safariManager = InAppSafariManager()

  func body(content: Content) -> some View {
    content
      .environment(\.openURL, OpenURLAction { url in
        // Open internal URL.
        routerPath.handle(url: url)
      })
      .onOpenURL { url in
        // Open external URL (from icecubesapp://)
        let urlString = url.absoluteString.replacingOccurrences(of: AppInfo.scheme, with: "https://")
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
          #if !targetEnvironment(macCatalyst)
            guard preferences.preferredBrowser == .inAppSafari else { return .systemAction }
          #endif
          // SFSafariViewController only supports initial URLs with http:// or https:// schemes.
          guard let scheme = url.scheme, ["https", "http"].contains(scheme.lowercased()) else {
            return .systemAction
          }
          return safariManager.open(url)
        }
      }
      .background {
        WindowReader { window in
          safariManager.windowScene = window.windowScene
        }
      }
  }
}

@MainActor
@Observable private class InAppSafariManager: NSObject, SFSafariViewControllerDelegate {
  var windowScene: UIWindowScene?
  let viewController: UIViewController = .init()
  var window: UIWindow?

  @MainActor
  func open(_ url: URL) -> OpenURLAction.Result {
    guard let windowScene else { return .systemAction }

    window = setupWindow(windowScene: windowScene)

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
    let window = window ?? UIWindow(windowScene: windowScene)

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

  nonisolated func safariViewControllerDidFinish(_: SFSafariViewController) {
    Task { @MainActor in
      window?.resignKey()
      window?.isHidden = false
      window = nil
    }
  }
}

private struct WindowReader: UIViewRepresentable {
  var onUpdate: (UIWindow) -> Void

  func makeUIView(context _: Context) -> InjectView {
    InjectView(onUpdate: onUpdate)
  }

  func updateUIView(_: InjectView, context _: Context) {}

  class InjectView: UIView {
    var onUpdate: (UIWindow) -> Void

    init(onUpdate: @escaping (UIWindow) -> Void) {
      self.onUpdate = onUpdate
      super.init(frame: .zero)
      isHidden = true
      isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
