import Combine
import UIKit

@Observable
public class SceneDelegate: NSObject, UIWindowSceneDelegate, Sendable {
  public var window: UIWindow?
  public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
  public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height

  public func scene(_ scene: UIScene,
                    willConnectTo _: UISceneSession,
                    options _: UIScene.ConnectionOptions)
  {
    guard let windowScene = scene as? UIWindowScene else { return }
    window = windowScene.keyWindow

    #if targetEnvironment(macCatalyst)
      if let titlebar = windowScene.titlebar {
        titlebar.titleVisibility = .hidden
        titlebar.toolbar = nil
      }
    #endif
  }

  override public init() {
    super.init()
    windowWidth = window?.bounds.size.width ?? UIScreen.main.bounds.size.width
    windowHeight = window?.bounds.size.height ?? UIScreen.main.bounds.size.height
    Self.observedSceneDelegate.insert(self)
    _ = Self.observer // just for activating the lazy static property
  }

  deinit {
    Task { @MainActor in
      Self.observedSceneDelegate.remove(self)
    }
  }

  private static var observedSceneDelegate: Set<SceneDelegate> = []
  private static let observer = Task {
    while true {
      try? await Task.sleep(for: .seconds(0.1))
      for delegate in observedSceneDelegate {
        let newWidth = delegate.window?.bounds.size.width ?? UIScreen.main.bounds.size.width
        if delegate.windowWidth != newWidth {
          delegate.windowWidth = newWidth
        }

        let newHeight = delegate.window?.bounds.size.height ?? UIScreen.main.bounds.size.height
        if delegate.windowHeight != newHeight {
          delegate.windowHeight = newHeight
        }
      }
    }
  }
}
