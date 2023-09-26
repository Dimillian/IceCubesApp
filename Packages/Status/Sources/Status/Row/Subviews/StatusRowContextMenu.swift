import DesignSystem
import Env
import Foundation
import Network
import SwiftUI

@MainActor
struct StatusRowContextMenu: View {
  @Environment(\.displayScale) var displayScale

  @Environment(Client.self) private var client
  @Environment(SceneDelegate.self) private var sceneDelegate
  @Environment(UserPreferences.self) private var preferences
  @Environment(CurrentAccount.self) private var account
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(StatusDataController.self) private var statusDataController

  var viewModel: StatusRowViewModel

  var boostLabel: some View {
    if viewModel.status.visibility == .priv, viewModel.status.account.id == account.account?.id {
      if statusDataController.isReblogged {
        return Label("status.action.unboost", systemImage: "lock.rotation")
      }
      return Label("status.action.boost-to-followers", systemImage: "lock.rotation")
    }

    if statusDataController.isReblogged {
      return Label("status.action.unboost", image: "Rocket")
    }
    return Label("status.action.boost", image: "Rocket")
  }

  var body: some View {
    if !viewModel.isRemote {
      Button { Task {
        await statusDataController.toggleFavorite(remoteStatus: nil)
      } } label: {
        Label(statusDataController.isFavorited ? "status.action.unfavorite" : "status.action.favorite", systemImage: "star")
      }
      Button { Task {
        await statusDataController.toggleReblog(remoteStatus: nil)
      } } label: {
        boostLabel
      }
      .disabled(viewModel.status.visibility == .direct || viewModel.status.visibility == .priv && viewModel.status.account.id != account.account?.id)
      Button { Task {
        await statusDataController.toggleBookmark(remoteStatus: nil)
      } } label: {
        Label(statusDataController.isBookmarked ? "status.action.unbookmark" : "status.action.bookmark",
              systemImage: "bookmark")
      }
      Button {
        viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
      } label: {
        Label("status.action.reply", systemImage: "arrowshape.turn.up.left")
      }
      Button {
        viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
      } label: {
        Label("status.action.quote", systemImage: "quote.bubble")
      }
      .disabled(viewModel.status.visibility == .direct || viewModel.status.visibility == .priv)
    }

    Divider()

    Menu("status.action.share-title") {
      if let urlString = viewModel.status.reblog?.url ?? viewModel.status.url,
         let url = URL(string: urlString)
      {
        ShareLink(item: url,
                  subject: Text(viewModel.status.reblog?.account.safeDisplayName ?? viewModel.status.account.safeDisplayName),
                  message: Text(viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText))
        {
          Label("status.action.share", systemImage: "square.and.arrow.up")
        }

        ShareLink(item: url) {
          Label("status.action.share-link", systemImage: "link")
        }

        Button {
          let view = HStack {
            StatusRowView(viewModel: viewModel)
              .padding(16)
          }
          .environment(\.isInCaptureMode, true)
          .environment(Theme.shared)
          .environment(preferences)
          .environment(account)
          .environment(currentInstance)
          .environment(SceneDelegate())
          .environment(QuickLook())
          .environment(viewModel.client)
          .preferredColorScheme(Theme.shared.selectedScheme == .dark ? .dark : .light)
          .foregroundColor(Theme.shared.labelColor)
          .background(Theme.shared.primaryBackgroundColor)
          .frame(width: sceneDelegate.windowWidth - 12)
          .tint(Theme.shared.tintColor)
          let renderer = ImageRenderer(content: view)
          renderer.scale = displayScale
          renderer.isOpaque = false
          if let image = renderer.uiImage {
            viewModel.routerPath.presentedSheet = .shareImage(image: image, status: viewModel.status)
          }
        } label: {
          Label("status.action.share-image", systemImage: "photo")
        }
      }
    }

    if let url = URL(string: viewModel.status.reblog?.url ?? viewModel.status.url ?? "") {
      Button { UIApplication.shared.open(url) } label: {
        Label("status.action.view-in-browser", systemImage: "safari")
      }
    }

    Button {
      UIPasteboard.general.string = viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText
    } label: {
      Label("status.action.copy-text", systemImage: "doc.on.doc")
    }

    Button {
      UIPasteboard.general.string = viewModel.status.reblog?.url ?? viewModel.status.url
    } label: {
      Label("status.action.copy-link", systemImage: "link")
    }

    if let lang = preferences.serverPreferences?.postLanguage ?? Locale.current.language.languageCode?.identifier
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
          Label(viewModel.isPinned ? "status.action.unpin" : "status.action.pin", systemImage: viewModel.isPinned ? "pin.fill" : "pin")
        }
        if currentInstance.isEditSupported {
          Button {
            viewModel.routerPath.presentedSheet = .editStatusEditor(status: viewModel.status.reblogAsAsStatus ?? viewModel.status)
          } label: {
            Label("status.action.edit", systemImage: "pencil")
          }
        }
        Button(role: .destructive,
               action: { viewModel.showDeleteAlert = true },
               label: { Label("status.action.delete", systemImage: "trash") })
      }
    } else {
      if !viewModel.isRemote {
        Section(viewModel.status.reblog?.account.acct ?? viewModel.status.account.acct) {
          Button {
            viewModel.routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.reblog?.account ?? viewModel.status.account, visibility: .pub)
          } label: {
            Label("status.action.mention", systemImage: "at")
          }
          Button {
            viewModel.routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.reblog?.account ?? viewModel.status.account, visibility: .direct)
          } label: {
            Label("status.action.message", systemImage: "tray.full")
          }

          if viewModel.authorRelationship?.blocking == true {
            Button {
              Task {
                do {
                  let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
                  viewModel.authorRelationship = try await client.post(endpoint: Accounts.unblock(id: operationAccount.id))
                } catch {
                  print("Error while unblocking: \(error.localizedDescription)")
                }
              }
            } label: {
              Label("account.action.unblock", systemImage: "person.crop.circle.badge.exclamationmark")
            }
          } else {
            Button {
              Task {
                do {
                  let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
                  viewModel.authorRelationship = try await client.post(endpoint: Accounts.block(id: operationAccount.id))
                } catch {
                  print("Error while blocking: \(error.localizedDescription)")
                }
              }
            } label: {
              Label("account.action.block", systemImage: "person.crop.circle.badge.xmark")
            }
          }

          if viewModel.authorRelationship?.muting == true {
            Button {
              Task {
                do {
                  let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
                  viewModel.authorRelationship = try await client.post(endpoint: Accounts.unmute(id: operationAccount.id))
                } catch {
                  print("Error while unmuting: \(error.localizedDescription)")
                }
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
                      let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
                      viewModel.authorRelationship = try await client.post(endpoint: Accounts.mute(id: operationAccount.id, json: MuteData(duration: duration.rawValue)))
                    } catch {
                      print("Error while muting: \(error.localizedDescription)")
                    }
                  }
                }
              }
            } label: {
              Label("account.action.mute", systemImage: "speaker.slash")
            }
          }
        }
      }
      Section {
        Button(role: .destructive) {
          viewModel.routerPath.presentedSheet = .report(status: viewModel.status.reblogAsAsStatus ?? viewModel.status)
        } label: {
          Label("status.action.report", systemImage: "exclamationmark.bubble")
        }
      }
    }
  }
}

struct ActivityView: UIViewControllerRepresentable {
  let image: Image

  func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image], applicationActivities: nil)
  }

  func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityView>) {}
}
