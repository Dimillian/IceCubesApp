import SwiftUI
import Models
import Network

@MainActor
public class StatusRowViewModel: ObservableObject {
  let status: Status
  let isEmbed: Bool
  let isFocused: Bool
  
  @Published var favouritesCount: Int
  @Published var isFavourited: Bool
  @Published var isReblogged: Bool
  @Published var reblogsCount: Int
  @Published var repliesCount: Int
  @Published var embededStatus: Status?
  @Published var displaySpoiler: Bool = false
  
  var client: Client?
  
  public init(status: Status,
              isEmbed: Bool = false,
              isFocused: Bool = false) {
    self.status = status
    self.isEmbed = isEmbed
    self.isFocused = isFocused
    if let reblog = status.reblog {
      self.isFavourited = reblog.favourited == true
      self.isReblogged = reblog.reblogged == true
    } else {
      self.isFavourited = status.favourited == true
      self.isReblogged = status.reblogged == true
    }
    self.favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    self.reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    self.repliesCount = status.reblog?.repliesCount ?? status.repliesCount
    self.displaySpoiler = !status.spoilerText.isEmpty
  }
  
  func loadEmbededStatus() async {
    guard let client,
          let ids = status.content.findStatusesIds(instance: client.server),
          !ids.isEmpty,
          let id = ids.first else { return }
    do {
      self.embededStatus = try await client.get(endpoint: Statuses.status(id: String(id)))
    } catch { }
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
    } else {
      isFavourited = status.favourited == true
      isReblogged = status.reblogged == true
    }
    favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    repliesCount = status.reblog?.repliesCount ?? status.repliesCount
  }
}
