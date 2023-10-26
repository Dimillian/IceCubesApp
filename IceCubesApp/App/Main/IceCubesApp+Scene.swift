import SwiftUI
import Env
import Status
import MediaUI

extension IceCubesApp {
  var appScene: some Scene {
    WindowGroup(id: "MainWindow") {
      appView
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

  @ViewBuilder
  private var appView: some View {
    if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
      sidebarView
    } else {
      tabBarView
    }
  }

  
  var otherScenes: some Scene {
    WindowGroup(for: WindowDestination.self) { destination in
      Group {
        switch destination.wrappedValue {
        case let .newStatusEditor(visibility):
          StatusEditorView(mode: .new(visibility: visibility))
        case let .editStatusEditor(status):
          StatusEditorView(mode: .edit(status: status))
        case let .quoteStatusEditor(status):
          StatusEditorView(mode: .quote(status: status))
        case let .replyToStatusEditor(status):
          StatusEditorView(mode: .replyTo(status: status))
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
    }
    .defaultSize(width: 600, height: 800)
    .windowResizability(.automatic)
  }
}
