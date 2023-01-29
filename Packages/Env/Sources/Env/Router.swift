import Foundation
import Models
import Network
import SwiftUI

public enum RouterDestinations: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case accountSettingsWithAccount(account: Account, appAccount: AppAccount)
  case statusDetail(id: String)
  case conversationDetail(conversation: Conversation)
  case remoteStatusDetail(url: URL)
  case hashTag(tag: String, account: String?)
  case list(list: Models.List)
  case followers(id: String)
  case following(id: String)
  case favoritedBy(id: String)
  case rebloggedBy(id: String)
}

public enum SheetDestinations: Identifiable {
  case newStatusEditor(visibility: Models.Visibility)
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  case mentionStatusEditor(account: Account, visibility: Models.Visibility)
  case listEdit(list: Models.List)
  case listAddAccount(account: Account)
  case addAccount
  case addRemoteLocalTimeline
  case statusEditHistory(status: String)
  case settings
  case accountPushNotficationsSettings

  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor,
         .mentionStatusEditor, .settings, .accountPushNotficationsSettings:
      return "statusEditor"
    case .listEdit:
      return "listEdit"
    case .listAddAccount:
      return "listAddAccount"
    case .addAccount:
      return "addAccount"
    case .addRemoteLocalTimeline:
      return "addRemoteLocalTimeline"
    case .statusEditHistory:
      return "statusEditHistory"
    }
  }
}

@MainActor
public class RouterPath: ObservableObject {
  public var client: Client?
  public var urlHandler: ((URL) -> OpenURLAction.Result)?

  @Published public var path: [RouterDestinations] = []
  @Published public var presentedSheet: SheetDestinations?

  public init() {}

  public func navigate(to: RouterDestinations) {
    path.append(to)
  }

  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if url.pathComponents.count == 3 && url.pathComponents[1] == "tags" &&
      url.host() == status.account.url?.host(),
      let tag = url.pathComponents.last
    {
      // OK this test looks weird but it's
      // A 3 component path i.e. ["/", "tags", "tagname"]
      // That is on the same host as the person that posted the tag,
      // i.e. not a link that matches the pattern but elsewhere on the internet
      // In those circumstances, hijack the link and goto the tags page instead
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if let mention = status.mentions.first(where: { $0.url == url }) {
      navigate(to: .accountDetail(id: mention.id))
      return .handled
    } else if let client = client,
              client.isAuth,
              client.hasConnection(with: url),
              let id = Int(url.lastPathComponent)
    {
      if url.absoluteString.contains(client.server) {
        navigate(to: .statusDetail(id: String(id)))
      } else {
        navigate(to: .remoteStatusDetail(url: url))
      }
      return .handled
    }
    return urlHandler?(url) ?? .systemAction
  }

  public func handle(url: URL) -> OpenURLAction.Result {
    if url.pathComponents.contains(where: { $0 == "tags" }),
       let tag = url.pathComponents.last
    {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if url.lastPathComponent.first == "@", let host = url.host {
      let acct = "\(url.lastPathComponent)@\(host)"
      Task {
        await navigateToAccountFrom(acct: acct, url: url)
      }
      return .handled
    } else if let client = client,
              client.isAuth,
              client.hasConnection(with: url),
              let id = Int(url.lastPathComponent)
    {
      if url.absoluteString.contains(client.server) {
        navigate(to: .statusDetail(id: String(id)))
      } else {
        navigate(to: .remoteStatusDetail(url: url))
      }
      return .handled
    }
    return urlHandler?(url) ?? .systemAction
  }

  public func navigateToAccountFrom(acct: String, url: URL) async {
    guard let client else { return }
    let results: SearchResults? = try? await client.get(endpoint: Search.search(query: acct,
                                                                                type: "accounts",
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
    if let account = results?.accounts.first {
      navigate(to: .accountDetailWithAccount(account: account))
    } else {
      await UIApplication.shared.open(url)
    }
  }

  public func navigateToAccountFrom(url: URL) async {
    guard let client else { return }
    let results: SearchResults? = try? await client.get(endpoint: Search.search(query: url.absoluteString,
                                                                                type: "accounts",
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
    if let account = results?.accounts.first {
      navigate(to: .accountDetailWithAccount(account: account))
    } else {
      await UIApplication.shared.open(url)
    }
  }
}
