import Combine
import DesignSystem
import Env
import Models
import NaturalLanguage
import Network
import SwiftUI

@MainActor
public class StatusRowViewModel: ObservableObject {
  let status: Status
  let isFocused: Bool
  // Whether this status is on a remote local timeline (many actions are unavailable if so)
  let isRemote: Bool
  let showActions: Bool
  let textDisabled: Bool
  let finalStatus: AnyStatus

  @Published var isPinned: Bool
  @Published var embeddedStatus: Status?
  @Published var displaySpoiler: Bool = false
  @Published var isEmbedLoading: Bool = false
  @Published var isFiltered: Bool = false

  @Published var translation: Translation?
  @Published var isLoadingTranslation: Bool = false
  @Published var showDeleteAlert: Bool = false

  private var actionsAccountsFetched: Bool = false
  @Published var favoriters: [Account] = []
  @Published var rebloggers: [Account] = []

  @Published var isLoadingRemoteContent: Bool = false
  @Published var localStatusId: String?
  @Published var localStatus: Status?

  // The relationship our user has to the author of this post, if available
  @Published var authorRelationship: Relationship? {
    didSet {
      // if we are newly blocking or muting the author, force collapse post so it goes away
      if let relationship = authorRelationship,
         relationship.blocking || relationship.muting
      {
        lineLimit = 0
      }
    }
  }

  // used by the button to expand a collapsed post
  @Published var isCollapsed: Bool = true {
    didSet {
      recalcCollapse()
    }
  }

  // number of lines to show, nil means show the whole post
  @Published var lineLimit: Int? = nil
  // post length determining if the post should be collapsed
  let collapseThresholdLength: Int = 750
  // number of text lines to show on a collpased post
  let collapsedLines: Int = 8
  // user preference, set in init
  var collapseLongPosts: Bool = false

  private func recalcCollapse() {
    let hasContentWarning = !status.spoilerText.asRawText.isEmpty
    let showCollapseButton = collapseLongPosts && isCollapsed && !hasContentWarning
      && finalStatus.content.asRawText.unicodeScalars.count > collapseThresholdLength
    let newlineLimit = showCollapseButton && isCollapsed ? collapsedLines : nil
    if newlineLimit != lineLimit {
      lineLimit = newlineLimit
    }
  }

  private let theme = Theme.shared
  private let userMentionned: Bool

  private var seen = false

  var filter: Filtered? {
    finalStatus.filtered?.first
  }

  var isThread: Bool {
    status.reblog?.inReplyToId != nil || status.reblog?.inReplyToAccountId != nil ||
      status.inReplyToId != nil || status.inReplyToAccountId != nil
  }

  var highlightRowColor: Color {
    if status.visibility == .direct {
      return theme.tintColor.opacity(0.15)
    } else if userMentionned {
      return theme.secondaryBackgroundColor
    } else {
      return theme.primaryBackgroundColor
    }
  }

  let client: Client
  let routerPath: RouterPath

  public init(status: Status,
              client: Client,
              routerPath: RouterPath,
              isFocused: Bool = false,
              isRemote: Bool = false,
              showActions: Bool = true,
              textDisabled: Bool = false)
  {
    self.status = status
    finalStatus = status.reblog ?? status
    self.client = client
    self.routerPath = routerPath
    self.isFocused = isFocused
    self.isRemote = isRemote
    self.showActions = showActions
    self.textDisabled = textDisabled
    if let reblog = status.reblog {
      isPinned = reblog.pinned == true
    } else {
      isPinned = status.pinned == true
    }
    if UserPreferences.shared.autoExpandSpoilers {
      displaySpoiler = false
    } else {
      displaySpoiler = !finalStatus.spoilerText.asRawText.isEmpty
    }

    if status.mentions.first(where: { $0.id == CurrentAccount.shared.account?.id }) != nil {
      userMentionned = true
    } else {
      userMentionned = false
    }

    isFiltered = filter != nil

    if let url = embededStatusURL(),
       let embed = StatusEmbedCache.shared.get(url: url)
    {
      isEmbedLoading = false
      embeddedStatus = embed
    }

    collapseLongPosts = UserPreferences.shared.collapseLongPosts
    recalcCollapse()
  }

  func markSeen() {
    // called in on appear so we can cache that the status has been seen.
    if UserPreferences.shared.suppressDupeReblogs && !seen {
      DispatchQueue.global().async { [weak self] in
        guard let self else { return }
        ReblogCache.shared.cache(self.status, seen: true)
        Task { @MainActor in
          self.seen = true
        }
      }
    }
  }

  func navigateToDetail() {
    guard !isFocused else { return }
    if isRemote, let url = URL(string: finalStatus.url ?? "") {
      routerPath.navigate(to: .remoteStatusDetail(url: url))
    } else {
      routerPath.navigate(to: .statusDetailWithStatus(status: status.reblogAsAsStatus ?? status))
    }
  }

  func navigateToAccountDetail(account: Account) {
    if isRemote, let url = account.url {
      withAnimation {
        isLoadingRemoteContent = true
      }
      Task {
        await routerPath.navigateToAccountFrom(url: url)
        isLoadingRemoteContent = false
      }
    } else {
      routerPath.navigate(to: .accountDetailWithAccount(account: account))
    }
  }

  func navigateToMention(mention: Mention) {
    if isRemote {
      withAnimation {
        isLoadingRemoteContent = true
      }
      Task {
        await routerPath.navigateToAccountFrom(url: mention.url)
        isLoadingRemoteContent = false
      }
    } else {
      routerPath.navigate(to: .accountDetail(id: mention.id))
    }
  }

  func loadAuthorRelationship() async {
    let relationships: [Relationship]? = try? await client.get(endpoint: Accounts.relationships(ids: [status.reblog?.account.id ?? status.account.id]))
    authorRelationship = relationships?.first
  }

  private func embededStatusURL() -> URL? {
    let content = finalStatus.content
    if !content.statusesURLs.isEmpty,
       let url = content.statusesURLs.first,
       !StatusEmbedCache.shared.badStatusesURLs.contains(url),
       client.hasConnection(with: url)
    {
      return url
    }
    return nil
  }

  func loadEmbeddedStatus() async {
    guard embeddedStatus == nil,
          let url = embededStatusURL()
    else {
      if isEmbedLoading {
        isEmbedLoading = false
      }
      return
    }

    if let embed = StatusEmbedCache.shared.get(url: url) {
      isEmbedLoading = false
      embeddedStatus = embed
      return
    }

    do {
      isEmbedLoading = true
      var embed: Status?
      if url.absoluteString.contains(client.server), let id = Int(url.lastPathComponent) {
        embed = try await client.get(endpoint: Statuses.status(id: String(id)))
      } else {
        let results: SearchResults = try await client.get(endpoint: Search.search(query: url.absoluteString,
                                                                                  type: "statuses",
                                                                                  offset: 0,
                                                                                  following: nil),
                                                          forceVersion: .v2)
        embed = results.statuses.first
      }
      if let embed {
        StatusEmbedCache.shared.set(url: url, status: embed)
      } else {
        StatusEmbedCache.shared.badStatusesURLs.insert(url)
      }
      withAnimation {
        embeddedStatus = embed
        isEmbedLoading = false
      }
    } catch {
      isEmbedLoading = false
      StatusEmbedCache.shared.badStatusesURLs.insert(url)
    }
  }

  func pin() async {
    guard client.isAuth else { return }
    isPinned = true
    do {
      let status: Status = try await client.post(endpoint: Statuses.pin(id: finalStatus.id))
      updateFromStatus(status: status)
    } catch {
      isPinned = false
    }
  }

  func unPin() async {
    guard client.isAuth else { return }
    isPinned = false
    do {
      let status: Status = try await client.post(endpoint: Statuses.unpin(id: finalStatus.id))
      updateFromStatus(status: status)
    } catch {
      isPinned = true
    }
  }

  func delete() async {
    do {
      _ = try await client.delete(endpoint: Statuses.status(id: status.id))
    } catch {}
  }

  func fetchActionsAccounts() async {
    guard !actionsAccountsFetched else { return }
    do {
      favoriters = try await client.get(endpoint: Statuses.favoritedBy(id: status.id, maxId: nil))
      rebloggers = try await client.get(endpoint: Statuses.rebloggedBy(id: status.id, maxId: nil))
      actionsAccountsFetched = true
    } catch {}
  }

  private func updateFromStatus(status: Status) {
    if let reblog = status.reblog {
      isPinned = reblog.pinned == true
    } else {
      isPinned = status.pinned == true
    }
  }

  func getStatusLang() -> String? {
    finalStatus.language
  }

  func translate(userLang: String) async {
    withAnimation {
      isLoadingTranslation = true
    }
    if !alwaysTranslateWithDeepl {
      do {
        // We first use instance translation API if available.
        let translation: Translation = try await client.post(endpoint: Statuses.translate(id: finalStatus.id,
                                                                                          lang: userLang))
        withAnimation {
          self.translation = translation
          isLoadingTranslation = false
        }

        return
      } catch {}
    }

    // If not or fail we use Ice Cubes own DeepL client.
    await translateWithDeepL(userLang: userLang)
  }

  func translateWithDeepL(userLang: String) async {
    withAnimation {
      isLoadingTranslation = true
    }

    let deepLClient = getDeepLClient()
    let translation = try? await deepLClient.request(target: userLang,
                                                     text: finalStatus.content.asRawText)
    withAnimation {
      self.translation = translation
      isLoadingTranslation = false
    }
  }

  private func getDeepLClient() -> DeepLClient {
    let userAPIfree = UserPreferences.shared.userDeeplAPIFree

    return DeepLClient(userAPIKey: userAPIKey, userAPIFree: userAPIfree)
  }

  private var userAPIKey: String? {
    DeepLUserAPIHandler.readIfAllowed()
  }

  var alwaysTranslateWithDeepl: Bool {
    DeepLUserAPIHandler.shouldAlwaysUseDeepl
  }

  func fetchRemoteStatus() async -> Bool {
    guard isRemote, let remoteStatusURL = URL(string: finalStatus.url ?? "") else { return false }
    isLoadingRemoteContent = true
    let results: SearchResults? = try? await client.get(endpoint: Search.search(query: remoteStatusURL.absoluteString,
                                                                                type: "statuses",
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
    if let status = results?.statuses.first {
      localStatusId = status.id
      localStatus = status
      isLoadingRemoteContent = false
      return true
    } else {
      isLoadingRemoteContent = false
      return false
    }
  }
}
