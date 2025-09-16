import Env
import Models
import NetworkClient
import SwiftUI

public struct AccountDetailContextMenu: View {
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences

  @Binding var showBlockConfirmation: Bool
  @Binding var showTranslateView: Bool

  var account: Account?
  @Binding var relationship: Relationship?
  let isCurrentUser: Bool

  public var body: some View {
    if let account = account {
      Section(account.acct) {
        if !isCurrentUser {
          Button {
            routerPath.presentedSheet = .mentionStatusEditor(
              account: account,
              visibility: preferences.postVisibility)
          } label: {
            Label("account.action.mention", systemImage: "at")
          }
          Button {
            routerPath.presentedSheet = .mentionStatusEditor(account: account, visibility: .direct)
          } label: {
            Label("account.action.message", systemImage: "tray.full")
          }

          #if !targetEnvironment(macCatalyst)
            Divider()
          #endif

          if relationship?.blocking == true {
            Button {
              Task {
                do {
                  relationship = try await client.post(
                    endpoint: Accounts.unblock(id: account.id))
                } catch {}
              }
            } label: {
              Label(
                "account.action.unblock", systemImage: "person.crop.circle.badge.exclamationmark")
            }
          } else {
            Button {
              showBlockConfirmation.toggle()
            } label: {
              Label("account.action.block", systemImage: "person.crop.circle.badge.xmark")
            }
          }

          if relationship?.muting == true {
            Button {
              Task {
                do {
                  relationship = try await client.post(
                    endpoint: Accounts.unmute(id: account.id))
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
                      relationship = try await client.post(
                        endpoint: Accounts.mute(
                          id: account.id, json: MuteData(duration: duration.rawValue)))
                    } catch {}
                  }
                }
              }
            } label: {
              Label("account.action.mute", systemImage: "speaker.slash")
            }
          }

          if let relationshipValue = relationship,
            relationshipValue.following
          {
            if relationshipValue.notifying {
              Button {
                Task {
                  do {
                    relationship = try await client.post(
                      endpoint: Accounts.follow(
                        id: account.id,
                        notify: false,
                        reblogs: relationshipValue.showingReblogs))
                  } catch {}
                }
              } label: {
                Label("account.action.notify-disable", systemImage: "bell.fill")
              }
            } else {
              Button {
                Task {
                  do {
                    relationship = try await client.post(
                      endpoint: Accounts.follow(
                        id: account.id,
                        notify: true,
                        reblogs: relationshipValue.showingReblogs))
                  } catch {}
                }
              } label: {
                Label("account.action.notify-enable", systemImage: "bell")
              }
            }
            if relationshipValue.showingReblogs {
              Button {
                Task {
                  do {
                    relationship = try await client.post(
                      endpoint: Accounts.follow(
                        id: account.id,
                        notify: relationshipValue.notifying,
                        reblogs: false))
                  } catch {}
                }
              } label: {
                Label("account.action.reboosts-hide", image: "Rocket.Fill")
              }
            } else {
              Button {
                Task {
                  do {
                    relationship = try await client.post(
                      endpoint: Accounts.follow(
                        id: account.id,
                        notify: relationshipValue.notifying,
                        reblogs: true))
                  } catch {}
                }
              } label: {
                Label("account.action.reboosts-show", systemImage: "arrow.2.squarepath")
              }
            }
          }

          #if !targetEnvironment(macCatalyst)
            Divider()
          #endif
        }

        #if canImport(_Translation_SwiftUI)
          if #available(iOS 17.4, *) {
            Button {
              showTranslateView = true
            } label: {
              Label("status.action.translate", systemImage: "captions.bubble")
            }
          }
        #endif

        if relationship?.following == true {
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
          Button {
            UIApplication.shared.open(url)
          } label: {
            Label("status.action.view-in-browser", systemImage: "safari")
          }
        }

        #if !targetEnvironment(macCatalyst)
          Divider()
        #endif
      }
    }
  }
}
