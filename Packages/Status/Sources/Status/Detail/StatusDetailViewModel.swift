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
    case loading, display(statuses: [Status]), error(error: Error)
  }

  @Published var state: State = .loading
  @Published var isLoadingContext = false
  @Published var title: LocalizedStringKey = ""
  @Published var scrollToId: String?

  init(statusId: String) {
    state = .loading
    self.statusId = statusId
    remoteStatusURL = nil
  }

  init(status: Status) {
    state = .display(statuses: [status])
    title = "status.post-from-\(status.account.displayNameWithoutEmojis)"
    statusId = status.id
    remoteStatusURL = nil
  }

  init(remoteStatusURL: URL) {
    state = .loading
    self.remoteStatusURL = remoteStatusURL
    statusId = nil
  }

  func fetch() async -> Bool {
    if statusId != nil {
      await fetchStatusDetail(animate: false)
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
      await fetchStatusDetail(animate: false)
      return true
    } else {
      return false
    }
  }

  struct ContextData {
    let status: Status
    let context: StatusContext
  }

  private func fetchStatusDetail(animate: Bool) async {
    guard let client, let statusId else { return }
    do {
      isLoadingContext = true
      let data = try await fetchContextData(client: client, statusId: statusId)
      title = "status.post-from-\(data.status.account.displayNameWithoutEmojis)"
      var statuses = data.context.ancestors
      statuses.append(data.status)
      statuses.append(contentsOf: data.context.descendants)
      if animate {
        withAnimation {
          isLoadingContext = false
          state = .display(statuses: statuses)
        }
      } else {
        isLoadingContext = false
        state = .display(statuses: statuses)
        scrollToId = statusId
      }
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
        await fetchStatusDetail(animate: true)
      }
    } else if event is StreamEventDelete {
      Task {
        await fetchStatusDetail(animate: true)
      }
    }
  }
}
