import Env
import MediaUI
import StatusKit
import SwiftUI

extension IceCubesApp {
  var appScene: some Scene {
    WindowGroup(id: "MainWindow") {
      AppView(selectedTab: $selectedTab, appRouterPath: $appRouterPath)
        .applyTheme(theme)
        .onAppear {
          setNewClientsInEnv(client: appAccountsManager.currentClient)
          setupRevenueCat()
          refreshPushSubs()
        }
        .environment(appAccountsManager)
        .environment(appAccountsManager.currentClient)
        .environment(quickLook)
        .environment(currentAccount)
        .environment(currentInstance)
        .environment(userPreferences)
        .environment(theme)
        .environment(watcher)
        .environment(pushNotificationsService)
        .environment(\.isSupporter, isSupporter)
        .sheet(item: $quickLook.selectedMediaAttachment) { selectedMediaAttachment in
          MediaUIView(selectedAttachment: selectedMediaAttachment,
                      attachments: quickLook.mediaAttachments)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(16)
            .withEnvironments()
        }
        .onChange(of: pushNotificationsService.handledNotification) { _, newValue in
          if newValue != nil {
            pushNotificationsService.handledNotification = nil
            if appAccountsManager.currentAccount.oauthToken?.accessToken != newValue?.account.token.accessToken,
               let account = appAccountsManager.availableAccounts.first(where:
                 { $0.oauthToken?.accessToken == newValue?.account.token.accessToken })
            {
              appAccountsManager.currentAccount = account
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedTab = .notifications
                pushNotificationsService.handledNotification = newValue
              }
            } else {
              selectedTab = .notifications
            }
          }
        }
        .withModelContainer()
    }
    #if targetEnvironment(macCatalyst)
    .defaultSize(width: userPreferences.showiPadSecondaryColumn ? 1100 : 800, height: 1400)
    #elseif os(visionOS)
    .defaultSize(width: 800, height: 1200)
    #endif
    .commands {
      appMenu
    }
    .onChange(of: scenePhase) { _, newValue in
      handleScenePhase(scenePhase: newValue)
    }
    .onChange(of: appAccountsManager.currentClient) { _, newValue in
      setNewClientsInEnv(client: newValue)
      if newValue.isAuth {
        watcher.watch(streams: [.user, .direct])
      }
    }
  }

  @SceneBuilder
  var otherScenes: some Scene {
    WindowGroup(for: WindowDestinationEditor.self) { destination in
      Group {
        switch destination.wrappedValue {
        case let .newStatusEditor(visibility):
          StatusEditor.MainView(mode: .new(visibility: visibility))
        case let .editStatusEditor(status):
          StatusEditor.MainView(mode: .edit(status: status))
        case let .quoteStatusEditor(status):
          StatusEditor.MainView(mode: .quote(status: status))
        case let .replyToStatusEditor(status):
          StatusEditor.MainView(mode: .replyTo(status: status))
        case let .mentionStatusEditor(account, visibility):
          StatusEditor.MainView(mode: .mention(account: account, visibility: visibility))
        case let .quoteLinkStatusEditor(link):
          StatusEditor.MainView(mode: .quoteLink(link: link))
        case .none:
          EmptyView()
        }
      }
      .withEnvironments()
      .withModelContainer()
      .applyTheme(theme)
      .frame(minWidth: 300, minHeight: 400)
    }
    .defaultSize(width: 600, height: 800)
    .windowResizability(.contentMinSize)

    WindowGroup(for: WindowDestinationMedia.self) { destination in
      Group {
        switch destination.wrappedValue {
        case let .mediaViewer(attachments, selectedAttachment):
          MediaUIView(selectedAttachment: selectedAttachment,
                      attachments: attachments)
        case .none:
          EmptyView()
        }
      }
      .withEnvironments()
      .withModelContainer()
      .applyTheme(theme)
      .frame(minWidth: 300, minHeight: 400)
    }
    .defaultSize(width: 1200, height: 1000)
    .windowResizability(.contentMinSize)
  }
}
