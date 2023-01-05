import SwiftUI
import Models
import Network

@MainActor
public class StatusRowViewModel: ObservableObject {
  let status: Status
  let isCompact: Bool
  let isFocused: Bool
  let showActions: Bool
  
  @Published var favouritesCount: Int
  @Published var isFavourited: Bool
  @Published var isReblogged: Bool
  @Published var isPinned: Bool
  @Published var reblogsCount: Int
  @Published var repliesCount: Int
  @Published var embededStatus: Status?
  @Published var displaySpoiler: Bool = false
  @Published var isEmbedLoading: Bool = true
  @Published var isFiltered: Bool = false
  
  var filter: Filtered? {
    status.reblog?.filtered?.first ?? status.filtered?.first
  }
  
  var client: Client?
  
  public init(status: Status,
              isCompact: Bool = false,
              isFocused: Bool = false,
              showActions: Bool = true) {
    self.status = status
    self.isCompact = isCompact
    self.isFocused = isFocused
    self.showActions = showActions
    if let reblog = status.reblog {
      self.isFavourited = reblog.favourited == true
      self.isReblogged = reblog.reblogged == true
      self.isPinned = reblog.pinned == true
    } else {
      self.isFavourited = status.favourited == true
      self.isReblogged = status.reblogged == true
      self.isPinned = status.pinned == true
    }
    self.favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    self.reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    self.repliesCount = status.reblog?.repliesCount ?? status.repliesCount
    self.displaySpoiler = !status.spoilerText.isEmpty
    
    self.isFiltered = filter != nil
  }
  
  func loadEmbededStatus() async {
    guard let client,
          let urls = status.content.findStatusesURLs(),
          !urls.isEmpty,
          let url = urls.first else {
      isEmbedLoading = false
      return
    }
    do {
      withAnimation {
        isEmbedLoading = true
      }
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
      withAnimation {
        embededStatus = embed
        isEmbedLoading = false
      }
    } catch {
      isEmbedLoading = false
    }
  }
  
  func favourite() async {
    guard let client, client.isAuth else { return }
    isFavourited = true
    favouritesCount += 1
    do {
      let status: Status = try await client.post(endpoint: Statuses.favourite(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isFavourited = false
      favouritesCount -= 1
    }
  }
  
  func unFavourite() async {
    guard let client, client.isAuth else { return }
    isFavourited = false
    favouritesCount -= 1
    do {
      let status: Status = try await client.post(endpoint: Statuses.unfavourite(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isFavourited = true
      favouritesCount += 1
    }
  }
  
  func reblog() async {
    guard let client, client.isAuth else { return }
    isReblogged = true
    reblogsCount += 1
    do {
      let status: Status = try await client.post(endpoint: Statuses.reblog(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isReblogged = false
      reblogsCount -= 1
    }
  }
  
  func unReblog() async {
    guard let client, client.isAuth else { return }
    isReblogged = false
    reblogsCount -= 1
    do {
      let status: Status = try await client.post(endpoint: Statuses.unreblog(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isReblogged = true
      reblogsCount += 1
    }
  }
  
  func pin() async {
    guard let client, client.isAuth else { return }
    isPinned = true
    do {
      let status: Status = try await client.post(endpoint: Statuses.pin(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isPinned = false
    }
  }
  
  func unPin() async {
    guard let client, client.isAuth else { return }
    isPinned = false
    do {
      let status: Status = try await client.post(endpoint: Statuses.unpin(id: status.reblog?.id ?? status.id))
      updateFromStatus(status: status)
    } catch {
      isPinned = true
    }
  }
  
  func delete() async {
    guard let client else { return }
    do {
      _ = try await client.delete(endpoint: Statuses.status(id: status.id))
    } catch { }
  }
  
  private func updateFromStatus(status: Status) {
    if let reblog = status.reblog {
      isFavourited = reblog.favourited == true
      isReblogged = reblog.reblogged == true
      isPinned = reblog.pinned == true
    } else {
      isFavourited = status.favourited == true
      isReblogged = status.reblogged == true
      isPinned = status.pinned == true
    }
    favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    repliesCount = status.reblog?.repliesCount ?? status.repliesCount
  }
}
