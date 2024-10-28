import Combine
import UIKit

@Observable
@MainActor public class SceneDelegate: NSObject, UIWindowSceneDelegate, Sendable {
  public var window: UIWindow?
  #if os(visionOS)
    public private(set) var windowWidth: CGFloat = 0
    public private(set) var windowHeight: CGFloat = 0
  #else
    public private(set) var windowWidth: CGFloat = UIScreen.main.bounds.size.width
    public private(set) var windowHeight: CGFloat = UIScreen.main.bounds.size.height
  #endif

  public func scene(
    _ scene: UIScene,
    willConnectTo _: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) {
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

    Task { @MainActor in
      setup()
    }
  }

  private func setup() {
    #if os(visionOS)
      windowWidth = window?.bounds.size.width ?? 0
      windowHeight = window?.bounds.size.height ?? 0
    #else
      windowWidth = window?.bounds.size.width ?? UIScreen.main.bounds.size.width
      windowHeight = window?.bounds.size.height ?? UIScreen.main.bounds.size.height
    #endif
    Self.observedSceneDelegate.insert(self)
    _ = Self.observer  // just for activating the lazy static property
  }

  private static var observedSceneDelegate: Set<SceneDelegate> = []
  private static let observer = Task { @MainActor in
    while true {
      try? await Task.sleep(for: .seconds(0.1))
      for delegate in observedSceneDelegate {
        #if os(visionOS)
          let newWidth = delegate.window?.bounds.size.width ?? 0
          if delegate.windowWidth != newWidth {
            delegate.windowWidth = newWidth
          }
          let newHeight = delegate.window?.bounds.size.height ?? 0
          if delegate.windowHeight != newHeight {
            delegate.windowHeight = newHeight
          }
        #else
          let newWidth = delegate.window?.bounds.size.width ?? UIScreen.main.bounds.size.width
          if delegate.windowWidth != newWidth {
            delegate.windowWidth = newWidth
          }
          let newHeight = delegate.window?.bounds.size.height ?? UIScreen.main.bounds.size.height
          if delegate.windowHeight != newHeight {
            delegate.windowHeight = newHeight
          }
        #endif
      }
    }
  }
}
