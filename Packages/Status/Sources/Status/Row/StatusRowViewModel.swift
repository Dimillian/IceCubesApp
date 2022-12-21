import SwiftUI
import Models
import Network

@MainActor
public class StatusRowViewModel: ObservableObject {
  let status: Status
  let isEmbed: Bool
  
  @Published var favouritesCount: Int
  @Published var isFavourited: Bool
  @Published var isReblogged: Bool
  @Published var reblogsCount: Int
  @Published var repliesCount: Int
  
  var client: Client?
  
  public init(status: Status, isEmbed: Bool) {
    self.status = status
    self.isEmbed = isEmbed
    self.isFavourited = status.reblog?.favourited ?? status.favourited
    self.favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    self.isReblogged = status.reblog?.reblogged ?? status.reblogged
    self.reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    self.repliesCount = status.reblog?.repliesCount ?? status.repliesCount
  }
  
  func favourite() async {
    guard let client else { return }
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
    guard let client else { return }
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
    guard let client else { return }
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
    guard let client else { return }
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
  
  private func updateFromStatus(status: Status) {
    isFavourited = status.reblog?.favourited ?? status.favourited
    favouritesCount = status.reblog?.favouritesCount ?? status.favouritesCount
    isReblogged = status.reblog?.reblogged ?? status.reblogged
    reblogsCount = status.reblog?.reblogsCount ?? status.reblogsCount
    repliesCount = status.reblog?.repliesCount ?? status.repliesCount
  }
}
