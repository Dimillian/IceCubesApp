import Combine
import Foundation
import Models
import NetworkClient
import Observation
import SwiftUI

public enum RouterDestination: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case accountSettingsWithAccount(account: Account, appAccount: AppAccount)
  case accountMediaGridView(account: Account, initialMediaStatuses: [MediaStatus])
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
  case quotes(id: String)
  case accountsList(accounts: [Account])
  case trendingTimeline
  case linkTimeline(url: URL, title: String)
  case trendingLinks(cards: [Card])
  case tagsList(tags: [Tag])
  case notificationsRequests
  case notificationForAccount(accountId: String)
  case blockedAccounts
  case mutedAccounts
  case conversations
  case instanceInfo(instance: Instance)
}

public enum WindowDestinationEditor: Hashable, Codable {
  case newStatusEditor(visibility: Models.Visibility)
  case prefilledStatusEditor(text: String, visibility: Models.Visibility)
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  case mentionStatusEditor(account: Account, visibility: Models.Visibility)
  case quoteLinkStatusEditor(link: URL)
}

public enum WindowDestinationMedia: Hashable, Codable {
  case mediaViewer(attachments: [MediaAttachment], selectedAttachment: MediaAttachment)
}

public enum SheetDestination: Identifiable, Hashable {
  public static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  case newStatusEditor(visibility: Models.Visibility)
  case prefilledStatusEditor(text: String, visibility: Models.Visibility)
  case imageURL(urls: [URL], caption: String?, altTexts: [String]?, visibility: Models.Visibility)
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  case quoteLinkStatusEditor(link: URL)
  case mentionStatusEditor(account: Account, visibility: Models.Visibility)
  case listCreate
  case listEdit(list: Models.List)
  case listAddAccount(account: Account)
  case addAccount
  case addRemoteLocalTimeline
  case addTagGroup
  case statusEditHistory(status: String)
  case settings
  case about
  case support
  case accountPushNotficationsSettings
  case report(status: Status)
  case shareImage(image: UIImage, status: Status)
  case editTagGroup(tagGroup: TagGroup, onSaved: ((TagGroup) -> Void)?)
  case timelineContentFilter
  case accountEditInfo
  case accountFiltersList

  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor,
      .mentionStatusEditor, .quoteLinkStatusEditor, .prefilledStatusEditor, .imageURL:
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
    case .settings, .support, .about, .accountPushNotficationsSettings:
      "settings"
    case .timelineContentFilter:
      "timelineContentFilter"
    case .accountEditInfo:
      "accountEditInfo"
    case .accountFiltersList:
      "accountFiltersList"
    }
  }
}

public enum SettingsStartingPoint {
  case display
  case haptic
  case remoteTimelines
  case tagGroups
  case recentTags
  case content
  case swipeActions
  case tabAndSidebarEntries
  case translation
}

@MainActor
@Observable public class RouterPath {
  public var client: MastodonClient?
  public var urlHandler: ((URL) -> OpenURLAction.Result)?

  public var path: [RouterDestination] = []
  public var presentedSheet: SheetDestination?

  public static var settingsStartingPoint: SettingsStartingPoint?

  public init() {}

  public func navigate(to: RouterDestination) {
    path.append(to)
  }

  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if url.pathComponents.count == 3,
      url.pathComponents[1] == "tags" || url.pathComponents[1] == "tag",
      url.host() == status.account.url?.host(),
      let tag = url.pathComponents.last
    {
      // OK this test looks weird but it's
      // A 3 component path i.e. ["/", "tags", "tagname"]
      // That is on the same host as the person that posted the tag,
      // i.e. not a link that matches the pattern but elsewhere on the internet
      // In those circumstances, hijack the link and goto the tags page instead
      // The second is "tags" on Mastodon and "tag" on Akkoma.
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if url.pathComponents.count == 4,
      url.pathComponents[1] == "discover",
      url.pathComponents[2] == "tags",
      url.host() == status.account.url?.host(),
      let tag = url.pathComponents.last
    {
      // Similar to above, but for ["/", "discover", "tags", "tagname"]
      // as used in Pixelfed
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
    guard let client, client.hasConnection(with: url) else {
      return urlHandler?(url) ?? .systemAction
    }

    if url.pathComponents.contains(where: { $0 == "tags" || $0 == "tag" }),
      let tag = url.pathComponents.last
    {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if url.lastPathComponent.first == "@",
      let host = url.host,
      !host.hasPrefix("www")
    {
      let acct = "\(url.lastPathComponent)@\(host)"
      Task {
        await navigateToAccountFrom(acct: acct, url: url)
      }
      return .handled
    } else if client.isAuth,
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

  public func handleDeepLink(url: URL) -> OpenURLAction.Result {
    guard let client,
      client.isAuth,
      let id = Int(url.lastPathComponent)
    else {
      return urlHandler?(url) ?? .systemAction
    }
    // First check whether we already know that the client's server federates with the server this post is on
    if client.hasConnection(with: url) {
      navigateToStatus(url: url, id: id)
      return .handled
    }
    Task {
      // Client does not currently report a federation relationship, but that doesn't mean none exists
      // Ensure client is aware of all peers its server federates with so it can give a meaningful answer to hasConnection(with:)
      do {
        let connections: [String] = try await client.get(endpoint: Instances.peers)
        client.addConnections(connections)
      } catch {
        handlerOrDefault(url: url)
        return
      }

      guard client.hasConnection(with: url) else {
        handlerOrDefault(url: url)
        return
      }

      navigateToStatus(url: url, id: id)
    }

    return .handled
  }

  private func navigateToStatus(url: URL, id: Int) {
    guard let client else { return }
    if url.absoluteString.contains(client.server) {
      navigate(to: .statusDetail(id: String(id)))
    } else {
      navigate(to: .remoteStatusDetail(url: url))
    }
  }

  private func handlerOrDefault(url: URL) {
    if let urlHandler {
      _ = urlHandler(url)
    } else {
      UIApplication.shared.open(url)
    }
  }

  public func navigateToAccountFrom(acct: String, url: URL) async {
    guard let client else { return }
    let results: SearchResults? = try? await client.get(
      endpoint: Search.search(
        query: acct,
        type: .accounts,
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
    let results: SearchResults? = try? await client.get(
      endpoint: Search.search(
        query: url.absoluteString,
        type: .accounts,
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
