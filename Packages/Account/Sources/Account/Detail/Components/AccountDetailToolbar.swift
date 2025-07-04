import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

struct AccountDetailToolbar: ToolbarContent {
  @Environment(\.openURL) private var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  let account: Account?
  let displayTitle: Bool
  let isCurrentUser: Bool
  @Binding var relationship: Relationship?
  @Binding var showBlockConfirmation: Bool
  @Binding var showTranslateView: Bool
  @Binding var isEditingRelationshipNote: Bool

  var body: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      if let account = account, displayTitle {
        VStack {
          Text(account.displayName ?? "").font(.headline)
          Text("account.detail.featured-tags-n-posts \(account.statusesCount ?? 0)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }

    ToolbarItemGroup(placement: .navigationBarTrailing) {
      if !isCurrentUser {
        Button {
          if let account = account {
            #if targetEnvironment(macCatalyst) || os(visionOS)
              openWindow(
                value: WindowDestinationEditor.mentionStatusEditor(
                  account: account, visibility: preferences.postVisibility))
            #else
              routerPath.presentedSheet = .mentionStatusEditor(
                account: account,
                visibility: preferences.postVisibility)
            #endif
          }
        } label: {
          Image(systemName: "arrowshape.turn.up.left")
        }
        .foregroundStyle(.primary)
      }

      Menu {
        AccountDetailContextMenu(
          showBlockConfirmation: $showBlockConfirmation,
          showTranslateView: $showTranslateView,
          account: account,
          relationship: $relationship,
          isCurrentUser: isCurrentUser)

        if !isCurrentUser {
          Button {
            isEditingRelationshipNote = true
          } label: {
            Label("account.relation.note.edit", systemImage: "pencil")
          }
        }

        if isCurrentUser {
          CurrentUserMenuItems(
            account: account,
            client: client,
            currentInstance: currentInstance,
            routerPath: routerPath,
            openURL: { url in openURL(url) }
          )
        }
      } label: {
        Image(systemName: "ellipsis")
          .accessibilityLabel("accessibility.tabs.profile.options.label")
          .accessibilityInputLabels([
            LocalizedStringKey("accessibility.tabs.profile.options.label"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel1"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel2"),
          ])
      }
      .foregroundStyle(.primary)
      .tint(.primary)
      .confirmationDialog("Block User", isPresented: $showBlockConfirmation) {
        if let account = account {
          Button("account.action.block-user-\(account.username)", role: .destructive) {
            Task {
              do {
                relationship = try await client.post(
                  endpoint: Accounts.block(id: account.id))
              } catch {}
            }
          }
        }
      } message: {
        Text("account.action.block-user-confirmation")
      }
      #if canImport(_Translation_SwiftUI)
        .addTranslateView(
          isPresented: $showTranslateView, text: account?.note.asRawText ?? "")
      #endif
    }
  }
}

private struct CurrentUserMenuItems: View {
  let account: Account?
  let client: MastodonClient
  let currentInstance: CurrentInstance
  let routerPath: RouterPath
  let openURL: (URL) -> Void

  var body: some View {
    Button {
      routerPath.presentedSheet = .accountEditInfo
    } label: {
      Label("account.action.edit-info", systemImage: "pencil")
    }

    Button {
      if let url = URL(string: "https://\(client.server)/settings/privacy") {
        openURL(url)
      }
    } label: {
      Label("account.action.privacy-settings", systemImage: "lock")
    }

    if currentInstance.isFiltersSupported {
      Button {
        routerPath.presentedSheet = .accountFiltersList
      } label: {
        Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
      }
    }

    Button {
      routerPath.presentedSheet = .accountPushNotficationsSettings
    } label: {
      Label("settings.push.navigation-title", systemImage: "bell")
    }

    if let account = account {
      Divider()

      Button {
        routerPath.navigate(to: .blockedAccounts)
      } label: {
        Label("account.blocked", systemImage: "person.crop.circle.badge.xmark")
      }

      Button {
        routerPath.navigate(to: .mutedAccounts)
      } label: {
        Label("account.muted", systemImage: "person.crop.circle.badge.moon")
      }

      Divider()

      Button {
        if let url = URL(
          string:
            "https://mastometrics.com/auth/login?username=\(account.acct)@\(client.server)&instance=\(client.server)&auto=true"
        ) {
          openURL(url)
        }
      } label: {
        Label("Mastometrics", systemImage: "chart.xyaxis.line")
      }

      Divider()
    }

    Button {
      routerPath.presentedSheet = .settings
    } label: {
      Label("settings.title", systemImage: "gear")
    }
  }
}
