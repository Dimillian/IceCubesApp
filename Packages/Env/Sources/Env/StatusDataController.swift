import Foundation
import SwiftUI
import Models
import Network

@MainActor
public protocol StatusDataControlling: ObservableObject {
  var isReblogged: Bool { get set }
  var isBookmarked: Bool { get set }
  var isFavorited: Bool { get set }
  
  var favoritesCount: Int { get set }
  var reblogsCount: Int { get set }
  var repliesCount: Int { get set }
  
  func toggleBookmark() async
  func toggleReblog() async
  func toggleFavorite() async
}

@MainActor
public final class StatusDataControllerProvider {
  public static let shared = StatusDataControllerProvider()
  
  private var cache: NSMutableDictionary = [:]
  
  private struct CacheKey: Hashable {
    let statusId: String
    let client: Client
  }
  
  public func dataController(for status: any AnyStatus, client: Client) -> StatusDataController {
    let key = CacheKey(statusId: status.id, client: client)
    if let controller = cache[key] as? StatusDataController {
      return controller
    }
    let controller = StatusDataController(status: status, client: client)
    cache[key] = controller
    return controller
  }
}

@MainActor
public final class StatusDataController: StatusDataControlling {
  private let status: AnyStatus
  private let client: Client
  
  @Published public var isReblogged: Bool
  @Published public var isBookmarked: Bool
  @Published public var isFavorited: Bool
  
  @Published public var favoritesCount: Int
  @Published public var reblogsCount: Int
  @Published public var repliesCount: Int
  
  init(status: AnyStatus, client: Client) {
    self.status = status
    self.client = client
    
    self.isReblogged = status.reblogged == true
    self.isBookmarked = status.bookmarked == true
    self.isFavorited = status.favourited == true
    
    self.reblogsCount = status.reblogsCount
    self.repliesCount = status.repliesCount
    self.favoritesCount = status.favouritesCount
  }
  
  public func updateFrom(status: Status) {
    self.isReblogged = status.reblogged == true
    self.isBookmarked = status.bookmarked == true
    self.isFavorited = status.favourited == true
    
    self.reblogsCount = status.reblogsCount
    self.repliesCount = status.repliesCount
    self.favoritesCount = status.favouritesCount
  }
  
  public func toggleFavorite() async {
    guard client.isAuth else { return }
    isFavorited.toggle()
    let endpoint = isFavorited ? Statuses.favorite(id: status.id) : Statuses.unfavorite(id: status.id)
    favoritesCount += isFavorited ? 1 : -1
    do {
      let status: Status = try await client.post(endpoint: endpoint)
      updateFrom(status: status)
    } catch {
      isFavorited.toggle()
      favoritesCount += isFavorited ? -1 : 1
    }
  }
  
  
  public func toggleReblog() async {
    guard client.isAuth else { return }
    isReblogged.toggle()
    let endpoint = isReblogged ? Statuses.reblog(id: status.id) : Statuses.unreblog(id: status.id)
    reblogsCount += isReblogged ? 1 : -1
    do {
      let status: Status = try await client.post(endpoint: endpoint)
      updateFrom(status: status)
    } catch {
      isReblogged.toggle()
      reblogsCount += isReblogged ? -1 : 1
    }
  }
  
  public func toggleBookmark() async {
    guard client.isAuth else { return }
    isBookmarked.toggle()
    let endpoint = isBookmarked ? Statuses.bookmark(id: status.id) : Statuses.unbookmark(id: status.id)
    do {
      let status: Status = try await client.post(endpoint: endpoint)
      updateFrom(status: status)
    } catch {
      isBookmarked.toggle()
    }
  }
}
