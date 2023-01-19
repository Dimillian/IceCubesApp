import Account
import AppAccount
import DesignSystem
import Env
import Network
import Status
import SwiftUI
import UIKit

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let appAccountsManager = AppAccountsManager.shared
    let client = appAccountsManager.currentClient
    let account = CurrentAccount.shared
    let instance = CurrentInstance.shared
    account.setClient(client: client)
    instance.setClient(client: client)
    let colorScheme = traitCollection.userInterfaceStyle
    let theme = Theme.shared
    theme.setColor(withName: colorScheme == .dark ? .iceCubeDark : .iceCubeLight)

    if let item = extensionContext?.inputItems.first as? NSExtensionItem {
      if let attachments = item.attachments {
        let view = StatusEditorView(mode: .shareExtension(items: attachments))
          .environmentObject(UserPreferences.shared)
          .environmentObject(appAccountsManager)
          .environmentObject(client)
          .environmentObject(account)
          .environmentObject(theme)
          .environmentObject(instance)
          .tint(theme.tintColor)
          .preferredColorScheme(colorScheme == .light ? .light : .dark)
        let childView = UIHostingController(rootView: view)
        addChild(childView)
        childView.view.frame = self.view.bounds
        self.view.addSubview(childView.view)
        childView.didMove(toParent: self)
      }
    }

    NotificationCenter.default.addObserver(forName: NotificationsName.shareSheetClose,
                                           object: nil,
                                           queue: nil) { _ in
      self.close()
    }
  }

  func close() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
}
