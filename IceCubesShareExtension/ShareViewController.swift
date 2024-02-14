import Account
import AppAccount
import DesignSystem
import Env
import Models
import Network
import StatusKit
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
    Task {
      await instance.fetchCurrentInstance()
    }
    let colorScheme = traitCollection.userInterfaceStyle
    let theme = Theme.shared
    theme.setColor(withName: colorScheme == .dark ? .iceCubeDark : .iceCubeLight)

    if let item = extensionContext?.inputItems.first as? NSExtensionItem {
      if let attachments = item.attachments {
        let view = StatusEditor.MainView(mode: .shareExtension(items: attachments))
          .environment(UserPreferences.shared)
          .environment(appAccountsManager)
          .environment(client)
          .environment(account)
          .environment(theme)
          .environment(instance)
          .modelContainer(for: [
            Draft.self,
            LocalTimeline.self,
            TagGroup.self,
            RecentTag.self,
          ])
          .tint(theme.tintColor)
          .preferredColorScheme(colorScheme == .light ? .light : .dark)
        let childView = UIHostingController(rootView: view)
        addChild(childView)
        childView.view.frame = self.view.bounds
        self.view.addSubview(childView.view)
        childView.didMove(toParent: self)

        childView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          childView.view.topAnchor.constraint(equalTo: self.view.topAnchor),
          childView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
          childView.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
          childView.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
      }
    }

    NotificationCenter.default.addObserver(forName: .shareSheetClose,
                                           object: nil,
                                           queue: nil)
    { [weak self] _ in
      self?.close()
    }
  }

  nonisolated func close() {
    Task { @MainActor in
      extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
}
