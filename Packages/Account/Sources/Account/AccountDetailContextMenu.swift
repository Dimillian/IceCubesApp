import Env
import Network
import SwiftUI

public struct AccountDetailContextMenu: View {
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences

  @Binding var showBlockConfirmation: Bool

  var viewModel: AccountDetailViewModel

  public var body: some View {
    if let account = viewModel.account {
      Section(account.acct) {
        if !viewModel.isCurrentUser {
          Button {
            routerPath.presentedSheet = .mentionStatusEditor(account: account,
                                                             visibility: preferences.postVisibility)
          } label: {
            Label("account.action.mention", systemImage: "at")
          }
          Button {
            routerPath.presentedSheet = .mentionStatusEditor(account: account, visibility: .direct)
          } label: {
            Label("account.action.message", systemImage: "tray.full")
          }

          Divider()

          if viewModel.relationship?.blocking == true {
            Button {
              Task {
                do {
                  viewModel.relationship = try await client.post(endpoint: Accounts.unblock(id: account.id))
                } catch {
                  print("Error while unblocking: \(error.localizedDescription)")
                }
              }
            } label: {
              Label("account.action.unblock", systemImage: "person.crop.circle.badge.exclamationmark")
            }
          } else {
            Button {
              showBlockConfirmation.toggle()
            } label: {
              Label("account.action.block", systemImage: "person.crop.circle.badge.xmark")
            }
          }

          if viewModel.relationship?.muting == true {
            Button {
              Task {
                do {
                  viewModel.relationship = try await client.post(endpoint: Accounts.unmute(id: account.id))
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
                      viewModel.relationship = try await client.post(endpoint: Accounts.mute(id: account.id, json: MuteData(duration: duration.rawValue)))
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

          if let relationship = viewModel.relationship,
             relationship.following
          {
            if relationship.notifying {
              Button {
                Task {
                  do {
                    viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                             notify: false,
                                                                                             reblogs: relationship.showingReblogs))
                  } catch {
                    print("Error while disabling notifications: \(error.localizedDescription)")
                  }
                }
              } label: {
                Label("account.action.notify-disable", systemImage: "bell.fill")
              }
            } else {
              Button {
                Task {
                  do {
                    viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                             notify: true,
                                                                                             reblogs: relationship.showingReblogs))
                  } catch {
                    print("Error while enabling notifications: \(error.localizedDescription)")
                  }
                }
              } label: {
                Label("account.action.notify-enable", systemImage: "bell")
              }
            }
            if relationship.showingReblogs {
              Button {
                Task {
                  do {
                    viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                             notify: relationship.notifying,
                                                                                             reblogs: false))
                  } catch {
                    print("Error while disabling reboosts: \(error.localizedDescription)")
                  }
                }
              } label: {
                Label("account.action.reboosts-hide", image: "Rocket.Fill")
              }
            } else {
              Button {
                Task {
                  do {
                    viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                             notify: relationship.notifying,
                                                                                             reblogs: true))
                  } catch {
                    print("Error while enabling reboosts: \(error.localizedDescription)")
                  }
                }
              } label: {
                Label("account.action.reboosts-show", image: "Rocket")
              }
            }
          }

          Divider()
        }

        if let lang = preferences.serverPreferences?.postLanguage ?? Locale.current.language.languageCode?.identifier {
          Button {
            Task {
              await viewModel.translate(userLang: lang)
            }
          } label: {
            Label("status.action.translate", systemImage: "captions.bubble")
          }
        }

        if viewModel.relationship?.following == true {
          Button {
            routerPath.presentedSheet = .listAddAccount(account: account)
          } label: {
            Label("account.action.add-remove-list", systemImage: "list.bullet")
          }
        }

        if let url = account.url {
          ShareLink(item: url, subject: Text(account.safeDisplayName)) {
            Label("account.action.share", systemImage: "square.and.arrow.up")
          }
          Button { UIApplication.shared.open(url) } label: {
            Label("status.action.view-in-browser", systemImage: "safari")
          }
        }

        Divider()
      }
    }
  }
}
