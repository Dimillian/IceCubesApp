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

          presentedURL = url
          return .handled
        }
      }
      .fullScreenCover(item: $presentedURL, content: { url in
        SafariView(url: url, inAppBrowserReaderView: preferences.inAppBrowserReaderView)
          .edgesIgnoringSafeArea(.all)
      })
  }

  struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let inAppBrowserReaderView: Bool

    func makeUIViewController(context _: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
      let configuration = SFSafariViewController.Configuration()
      configuration.entersReaderIfAvailable = inAppBrowserReaderView

      let safari = SFSafariViewController(url: url, configuration: configuration)
      safari.preferredBarTintColor = UIColor(Theme.shared.primaryBackgroundColor)
      safari.preferredControlTintColor = UIColor(Theme.shared.tintColor)
      return safari
    }

    func updateUIViewController(_: SFSafariViewController, context _: UIViewControllerRepresentableContext<SafariView>) {}
  }
}
