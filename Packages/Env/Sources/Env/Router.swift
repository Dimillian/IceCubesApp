import Combine
import Foundation
import Models
import Network
import Observation
import SwiftUI

public enum RouterDestination: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case accountSettingsWithAccount(account: Account, appAccount: AppAccount)
  case statusDetail(id: String)
  case statusDetailWithStatus(status: Status)
  case remoteStatusDetail(url: URL)
  case conversationDetail(conversation: Conversation)
  case hashTag(tag: String, account: String?)
  case list(list: Models.List)
  case followers(id: String)
  case following(id: String)
  case favoritedBy(id: String)
  case rebloggedBy(id: String)
  case accountsList(accounts: [Account])
  case trendingTimeline
  case trendingLinks(cards: [Card])
  case tagsList(tags: [Tag])
}

public enum WindowDestinationEditor: Hashable, Codable {
  case newStatusEditor(visibility: Models.Visibility)
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
}

public enum WindowDestinationMedia: Hashable, Codable {
  case mediaViewer(attachments: [MediaAttachment], selectedAttachment: MediaAttachment)
}

public enum SheetDestination: Identifiable {
  case newStatusEditor(visibility: Models.Visibility)
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  case mentionStatusEditor(account: Account, visibility: Models.Visibility)
  case listCreate
  case listEdit(list: Models.List)
  case listAddAccount(account: Account)
  case addAccount
  case addRemoteLocalTimeline
  case addTagGroup
  case statusEditHistory(status: String)
  case settings
  case accountPushNotficationsSettings
  case report(status: Status)
  case shareImage(image: UIImage, status: Status)
  case editTagGroup(tagGroup: TagGroup, onSaved: ((TagGroup) -> Void)?)

  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor,
         .mentionStatusEditor, .settings, .accountPushNotficationsSettings:
      "statusEditor"
    case .listCreate:
      "listCreate"
    case .listEdit:
      "listEdit"
    case .listAddAccount:
      "listAddAccount"
    case .addAccount:
      "addAccount"
    case .addTagGroup:
      "addTagGroup"
    case .addRemoteLocalTimeline:
      "addRemoteLocalTimeline"
    case .statusEditHistory:
      "statusEditHistory"
    case .report:
      "report"
    case .shareImage:
      "shareImage"
    case .editTagGroup:
      "editTagGroup"
    }
  }
}

@MainActor
@Observable public class RouterPath {
  public var client: Client?
  public var urlHandler: ((URL) -> OpenURLAction.Result)?

  public var path: [RouterDestination] = []
  public var presentedSheet: SheetDestination?

  public init() {}

  public func navigate(to: RouterDestination) {
    path.append(to)
  }

  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if url.pathComponents.count == 3, url.pathComponents[1] == "tags",
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
    } else if let client,
              client.isAuth,
              client.hasConnection(with: url),
              let id = Int(url.lastPathComponent)
    {
      if !StatusEmbedCache.shared.badStatusesURLs.contains(url) {
        if url.absoluteString.contains(client.server) {
          navigate(to: .statusDetail(id: String(id)))
        } else {
          navigate(to: .remoteStatusDetail(url: url))
        }
        return .handled
      }
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
    } else if let client,
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
      _ = await UIApplication.shared.open(url)
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
      _ = await UIApplication.shared.open(url)
    }
  }
}
