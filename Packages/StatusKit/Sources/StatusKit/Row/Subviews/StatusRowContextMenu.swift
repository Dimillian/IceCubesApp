import DesignSystem
import Env
import Foundation
import NetworkClient
import SwiftUI

@MainActor
struct StatusRowContextMenu: View {
  @Environment(\.openWindow) var openWindow

  @Environment(MastodonClient.self) private var client
  @Environment(SceneDelegate.self) private var sceneDelegate
  @Environment(UserPreferences.self) private var preferences
  @Environment(CurrentAccount.self) private var account
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(StatusDataController.self) private var statusDataController
  @Environment(QuickLook.self) private var quickLook
  @Environment(Theme.self) private var theme

  var viewModel: StatusRowViewModel
  @Binding var showTextForSelection: Bool
  @Binding var isBlockConfirmationPresented: Bool
  @Binding var isShareAsImageSheetPresented: Bool

  var boostLabel: some View {
    if viewModel.status.visibility == .priv, viewModel.status.account.id == account.account?.id {
      if statusDataController.isReblogged {
        return Label("status.action.unboost", systemImage: "lock.rotation")
      }
      return Label("status.action.boost-to-followers", systemImage: "lock.rotation")
    }

    return Label("status.action.boost", systemImage: "arrow.2.squarepath")
  }

  var isQuoteDisabled: Bool {
    viewModel.finalStatus.quoteApproval?.currentUser == .denied
      || viewModel.finalStatus.visibility != .pub
  }

  var isBoostDisabled: Bool {
    switch viewModel.finalStatus.visibility {
    case .pub:
      return false
    case .priv:
      guard let currentAccountId = account.account?.id else { return true }
      return viewModel.finalStatus.account.id != currentAccountId
    case .unlisted, .direct:
      return true
    }
  }

  var body: some View {
    if !viewModel.isRemote {
      ControlGroup {
        Button {
          #if targetEnvironment(macCatalyst) || os(visionOS)
            openWindow(value: WindowDestinationEditor.replyToStatusEditor(status: viewModel.status))
          #else
            viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
          #endif
        } label: {
          Label("status.action.reply", systemImage: "arrowshape.turn.up.left")
        }
        Button {
          Task {
            HapticManager.shared.fireHaptic(.notification(.success))
            SoundEffectManager.shared.playSound(.boost)
            await statusDataController.toggleReblog(remoteStatus: nil)
          }
        } label: {
          boostLabel
        }
        .disabled(isBoostDisabled)
        .opacity(isBoostDisabled ? 0.35 : 1)

        Button {
          Task {
            HapticManager.shared.fireHaptic(.notification(.success))
            SoundEffectManager.shared.playSound(.favorite)
            await statusDataController.toggleFavorite(remoteStatus: nil)
          }
        } label: {
          Label(
            statusDataController.isFavorited
              ? "status.action.unfavorite" : "status.action.favorite",
            systemImage: statusDataController.isFavorited ? "star.fill" : "star")
        }

        Button {
          Task {
            SoundEffectManager.shared.playSound(.bookmark)
            HapticManager.shared.fireHaptic(.notification(.success))
            await statusDataController.toggleBookmark(remoteStatus: nil)
          }
        } label: {
          Label(
            statusDataController.isBookmarked
              ? "status.action.unbookmark" : "status.action.bookmark",
            systemImage: statusDataController.isBookmarked ? "bookmark.fill" : "bookmark")
        }
      }
      .controlGroupStyle(.compactMenu)
      if !isQuoteDisabled {
        Button {
          #if targetEnvironment(macCatalyst) || os(visionOS)
            openWindow(value: WindowDestinationEditor.quoteStatusEditor(status: viewModel.status))
          #else
            viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
          #endif
        } label: {
          Label("status.action.quote", systemImage: "quote.bubble")
        }
      }
    }

    Divider()

    Menu {
      if let url = viewModel.url {
        ShareLink(
          item: url,
          subject: Text(
            viewModel.status.reblog?.account.safeDisplayName
              ?? viewModel.status.account.safeDisplayName),
          message: Text(
            viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText)
        ) {
          Label("status.action.share", systemImage: "square.and.arrow.up")
        }

        ShareLink(item: url) {
          Label("status.action.share-link", systemImage: "link")
        }

        Button {
          isShareAsImageSheetPresented = true
        } label: {
          Label("status.action.share-image", systemImage: "photo")
        }
      }
    } label: {
      Label("status.action.share-title", systemImage: "square.and.arrow.up")
    }

    if let url = viewModel.url {
      Button {
        UIApplication.shared.open(url)
      } label: {
        Label("status.action.view-in-browser", systemImage: "safari")
      }
    }

    Button {
      UIPasteboard.general.string =
        viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText
    } label: {
      Label("status.action.copy-text", systemImage: "doc.on.doc")
    }

    Button {
      showTextForSelection = true
    } label: {
      Label("status.action.select-text", systemImage: "selection.pin.in.out")
    }

    Button {
      UIPasteboard.general.string = viewModel.url?.absoluteString
    } label: {
      Label("status.action.copy-link", systemImage: "link")
    }

    if let lang = preferences.serverPreferences?.postLanguage
      ?? Locale.current.language.languageCode?.identifier
    {
      Button {
        Task {
          await viewModel.translate(userLang: lang)
        }
      } label: {
        Label("status.action.translate", systemImage: "captions.bubble")
      }
    }

    if account.account?.id == viewModel.status.reblog?.account.id ?? viewModel.status.account.id {
      Section("status.action.section.your-post") {
        Button {
          Task {
            if viewModel.isPinned {
              await viewModel.unPin()
            } else {
              await viewModel.pin()
            }
          }
        } label: {
          Label(
            viewModel.isPinned ? "status.action.unpin" : "status.action.pin",
            systemImage: viewModel.isPinned ? "pin.fill" : "pin")
        }
        if currentInstance.isEditSupported {
          Button {
            #if targetEnvironment(macCatalyst) || os(visionOS)
              openWindow(
                value: WindowDestinationEditor.editStatusEditor(
                  status: viewModel.status.reblogAsAsStatus ?? viewModel.status))
            #else
              viewModel.routerPath.presentedSheet = .editStatusEditor(
                status: viewModel.status.reblogAsAsStatus ?? viewModel.status)
            #endif
          } label: {
            Label("status.action.edit", systemImage: "pencil")
          }
        }
        Button(
          role: .destructive,
          action: { viewModel.showDeleteAlert = true },
          label: { Label("status.action.delete", systemImage: "trash") })
      }
    } else {
      if !viewModel.isRemote {
        Section(viewModel.status.reblog?.account.acct ?? viewModel.status.account.acct) {
          if viewModel.authorRelationship?.muting == true {
            Button {
              Task {
                do {
                  let operationAccount =
                    viewModel.status.reblog?.account ?? viewModel.status.account
                  viewModel.authorRelationship = try await client.post(
                    endpoint: Accounts.unmute(id: operationAccount.id))
                } catch {}
              }
            } label: {
              Label("account.action.unmute", systemImage: "speaker")
            }
          } else {
            Menu {
              ForEach(Duration.mutingDurations(), id: \.rawValue) { duration in
                Button(duration.description) {
                  Task {
                    do {
                      let operationAccount =
                        viewModel.status.reblog?.account ?? viewModel.status.account
                      viewModel.authorRelationship = try await client.post(
                        endpoint: Accounts.mute(
                          id: operationAccount.id, json: MuteData(duration: duration.rawValue)))
                    } catch {}
                  }
                }
              }
            } label: {
              Label("account.action.mute", systemImage: "speaker.slash")
            }
          }

          #if targetEnvironment(macCatalyst)
            accountContactMenuItems
          #else
            ControlGroup {
              accountContactMenuItems
            }
          #endif
        }
      }
      Section {
        Button(role: .destructive) {
          viewModel.routerPath.presentedSheet = .report(
            status: viewModel.status.reblogAsAsStatus ?? viewModel.status)
        } label: {
          Label("status.action.report", systemImage: "exclamationmark.bubble")
        }
      }
    }
  }

  @ViewBuilder
  private var accountContactMenuItems: some View {
    Button {
      #if targetEnvironment(macCatalyst) || os(visionOS)
        openWindow(
          value: WindowDestinationEditor.mentionStatusEditor(
            account: viewModel.status.reblog?.account ?? viewModel.status.account, visibility: .pub)
        )
      #else
        viewModel.routerPath.presentedSheet = .mentionStatusEditor(
          account: viewModel.status.reblog?.account ?? viewModel.status.account, visibility: .pub)
      #endif
    } label: {
      Label("status.action.mention", systemImage: "at")
    }
    Button {
      #if targetEnvironment(macCatalyst) || os(visionOS)
        openWindow(
          value: WindowDestinationEditor.mentionStatusEditor(
            account: viewModel.status.reblog?.account ?? viewModel.status.account,
            visibility: .direct))
      #else
        viewModel.routerPath.presentedSheet = .mentionStatusEditor(
          account: viewModel.status.reblog?.account ?? viewModel.status.account, visibility: .direct
        )
      #endif
    } label: {
      Label("status.action.message", systemImage: "tray.full")
    }
    if viewModel.authorRelationship?.blocking == true {
      Button {
        Task {
          do {
            let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
            viewModel.authorRelationship = try await client.post(
              endpoint: Accounts.unblock(id: operationAccount.id))
          } catch {}
        }
      } label: {
        Label("account.action.unblock", systemImage: "person.crop.circle.badge.exclamationmark")
      }
    } else {
      Button {
        isBlockConfirmationPresented = true
      } label: {
        Label("account.action.block", systemImage: "person.crop.circle.badge.xmark")
      }
    }
  }
}
