import SwiftUI
import Models
import Network

@MainActor
public class StatusRowViewModel: ObservableObject {
  let status: Status
  let isEmbed: Bool
  
  @Published var favouritesCount: Int
  @Published var isFavourited: Bool
  
  var client: Client?
  
  public init(status: Status, isEmbed: Bool) {
    self.status = status
    self.isEmbed = isEmbed
    self.isFavourited = status.favourited
    self.favouritesCount = status.favouritesCount
  }
  
  func favourite() async {
    guard let client else { return }
    isFavourited = true
    favouritesCount += 1
    do {
      let status: Status = try await client.post(endpoint: Statuses.favourite(id: status.id))
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
      let status: Status = try await client.post(endpoint: Statuses.unfavourite(id: status.id))
      updateFromStatus(status: status)
    } catch {
      isFavourited = true
      favouritesCount += 1
    }
  }
  
  private func updateFromStatus(status: Status) {
    isFavourited = status.favourited
    favouritesCount = status.favouritesCount
  }
}
