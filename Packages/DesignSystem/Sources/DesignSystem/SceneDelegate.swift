import UIKit

public class SceneDelegate: NSObject, ObservableObject, UIWindowSceneDelegate {
  public var window: UIWindow?
  
  public var windowWidth: CGFloat {
    window?.bounds.size.width ?? UIScreen.main.bounds.size.width
  }
  
  public func scene(_ scene: UIScene,
                    willConnectTo session: UISceneSession,
                    options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    self.window = windowScene.keyWindow
  }
}
