import Foundation
import Models
import Network
import SwiftUI

@MainActor
class StatusDetailViewModel: ObservableObject {
  public var statusId: String?
  public var remoteStatusURL: URL?

  var client: Client?

  enum State {
    case loading, display(status: Status, context: StatusContext), error(error: Error)
  }

  @Published var state: State = .loading
  @Published var title: LocalizedStringKey = ""

  init(statusId: String) {
    state = .loading
    self.statusId = statusId
    remoteStatusURL = nil
  }

  init(remoteStatusURL: URL) {
    state = .loading
    self.remoteStatusURL = remoteStatusURL
    statusId = nil
  }

  func fetch() async -> Bool {
    if statusId != nil {
      await fetchStatusDetail()
      return true
    } else if remoteStatusURL != nil {
      return await fetchRemoteStatus()
    }
    return false
  }

  private func fetchRemoteStatus() async -> Bool {
    guard let client, let remoteStatusURL else { return false }
    let results: SearchResults? = try? await client.get(endpoint: Search.search(query: remoteStatusURL.absoluteString,
                                                                                type: "statuses",
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
    if let statusId = results?.statuses.first?.id {
      self.statusId = statusId
      await fetchStatusDetail()
      return true
    } else {
      return false
    }
  }

  struct ContextData {
    let status: Status
    let context: StatusContext
  }

  private func fetchStatusDetail() async {
    guard let client, let statusId else { return }
    do {
      let data = try await fetchContextData(client: client, statusId: statusId)
      state = .display(status: data.status, context: data.context)
      title = "status.post-from-\(data.status.account.displayNameWithoutEmojis)"
    } catch {
      state = .error(error: error)
    }
  }

  private func fetchContextData(client: Client, statusId: String) async throws -> ContextData {
    async let status: Status = client.get(endpoint: Statuses.status(id: statusId))
    async let context: StatusContext = client.get(endpoint: Statuses.context(id: statusId))
    return try await .init(status: status, context: context)
  }

  func handleEvent(event: any StreamEvent, currentAccount: Account?) {
    if let event = event as? StreamEventUpdate,
       event.status.account.id == currentAccount?.id
    {
      Task {
        await fetchStatusDetail()
      }
    } else if event is StreamEventDelete {
      Task {
        await fetchStatusDetail()
      }
    }
  }
}
