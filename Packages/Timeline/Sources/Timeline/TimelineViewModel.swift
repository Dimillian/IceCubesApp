import Env
import Models
import Network
import Status
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject, StatusesFetcher {
  var client: Client? {
    didSet {
      if oldValue != client {
        statuses = []
      }
    }
  }

  // Internal source of truth for a timeline.
  private var statuses: [Status] = []

  @Published var statusesState: StatusesState = .loading
  @Published var timeline: TimelineFilter = .federated {
    didSet {
      Task {
        if oldValue != timeline {
          statuses = []
          pendingStatuses = []
          tag = nil
          digest = nil
        }
        await fetchStatuses(userIntent: false)
        switch timeline {
        case let .hashtag(tag, _):
          await fetchTag(id: tag)
        default:
          break
        }
      }
    }
  }

  @Published var tag: Tag?
  @Published var digest: Digest?
  
  var acct: String?

  enum PendingStatusesState {
    case refresh, stream
  }

  @Published var pendingStatuses: [Status] = []
  @Published var pendingStatusesState: PendingStatusesState = .stream

  var pendingStatusesButtonTitle: LocalizedStringKey {
    switch pendingStatusesState {
    case .stream, .refresh:
      return "timeline.n-new-posts \(pendingStatuses.count)"
    }
  }

  var pendingStatusesEnabled: Bool {
    timeline == .home
  }

  var serverName: String {
    client?.server ?? "Error"
  }

  func fetchStatuses() async {
    await fetchStatuses(userIntent: false)
  }

  func fetchStatuses(userIntent: Bool) async {
    guard let client else { return }
    do {
      if statuses.isEmpty {
        pendingStatuses = []
        statusesState = .loading
        if timeline == TimelineFilter.digest {
          statuses = await digestTimeline()
        } else {
          statuses = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                           maxId: nil,
                                                           minId: nil,
                                                           offset: statuses.count))
        }
        withAnimation {
          statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
        }
      } else if let first = pendingStatuses.first ?? statuses.first {
        if timeline == TimelineFilter.digest {
          return
        }
        var newStatuses: [Status] = await fetchNewPages(minId: first.id, maxPages: 20)
        if userIntent || !pendingStatusesEnabled {
          pendingStatuses.insert(contentsOf: newStatuses, at: 0)
          statuses.insert(contentsOf: pendingStatuses, at: 0)
          pendingStatuses = []
          withAnimation {
            statusesState = .display(statuses: statuses, nextPageState: statuses.count < 20 ? .none : .hasNextPage)
          }
        } else {
          newStatuses = newStatuses.filter { status in
            !pendingStatuses.contains(where: { $0.id == status.id })
          }
          pendingStatuses.insert(contentsOf: newStatuses, at: 0)
          pendingStatusesState = .refresh
        }
      }
    } catch {
      statusesState = .error(error: error)
      print("timeline parse error: \(error)")
    }
  }
  
  func digestTimeline() async -> [Status] {
    // fetch all the statuses until specified time (last 24 hours) and then run the algorithm
    let hoursAgo = 24

    // Get as many posts as possible (max seems to be 400 though https://github.com/mastodon/mastodon/issues/2301)
    let earlyDate = Calendar.current.date(
      byAdding: .hour,
      value: -hoursAgo,
      to: Date()
    )!
    let timestamp = ISO8601DateFormatter().string(from: earlyDate)
    let allStatuses = await fetchNewPages(minId: timestamp, maxPages: 400)

    var originals: [Status] = []
    var boosts: [Status] = []
    var postsSeen: Set<String> = []
    // ignore my posts or posts I interacted with
    for status in allStatuses
      where
        status.isRelevant() &&
        !status.didInteract() &&
        !postsSeen.contains(status.reblog?.url ?? status.url ?? "") &&
        acct?.lowercased() != status.account.acct.lowercased() &&
        !status.account.note.asRawText.lowercased().contains("#noindex") &&
        !status.account.note.asRawText.lowercased().contains("#nobot")
    {
          if status.reblog == nil {
            originals.append(status)
          } else {
            boosts.append(status)
          }
          postsSeen.insert(status.reblog?.url ?? status.url ?? "")
    }

    digest = Digest(
      generatedAt: timestamp,
      totalStatuses: originals.count + boosts.count
    )
    return originals.gatherPopular(percentile: 95) + boosts.gatherPopular(percentile: 95)
  }

  func fetchNewPages(minId: String, maxPages: Int) async -> [Status] {
    guard let client else { return [] }
    var pagesLoaded = 0
    var allStatuses: [Status] = []
    var latestMinId = minId
    do {
      while let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                         maxId: nil,
                                                                                         minId: latestMinId,
                                                                                         offset: statuses.count)),
        !newStatuses.isEmpty,
        pagesLoaded < maxPages
      {
        pagesLoaded += 1
        allStatuses.insert(contentsOf: newStatuses, at: 0)
        latestMinId = newStatuses.first?.id ?? ""
      }
    } catch {
      return allStatuses
    }
    return allStatuses
  }

  func fetchNextPage() async {
    guard let client else { return }
    do {
      guard let lastId = statuses.last?.id else { return }
      statusesState = .display(statuses: statuses, nextPageState: .loadingNextPage)
      let newStatuses: [Status] = try await client.get(endpoint: timeline.endpoint(sinceId: nil,
                                                                                   maxId: lastId,
                                                                                   minId: nil,
                                                                                   offset: statuses.count))
      statuses.append(contentsOf: newStatuses)
      statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
    } catch {
      statusesState = .error(error: error)
    }
  }

  func fetchTag(id: String) async {
    guard let client else { return }
    do {
      tag = try await client.get(endpoint: Tags.tag(id: id))
    } catch {}
  }

  func handleEvent(event: any StreamEvent, currentAccount: CurrentAccount) {
    if let event = event as? StreamEventUpdate,
       pendingStatusesEnabled,
       !statuses.contains(where: { $0.id == event.status.id }),
       !pendingStatuses.contains(where: { $0.id == event.status.id })
    {
      if event.status.account.id == currentAccount.account?.id, pendingStatuses.isEmpty {
        withAnimation {
          statuses.insert(event.status, at: 0)
          statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
        }
      } else {
        pendingStatuses.insert(event.status, at: 0)
        pendingStatusesState = .stream
      }
    } else if let event = event as? StreamEventDelete {
      withAnimation {
        statuses.removeAll(where: { $0.id == event.status })
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    } else if let event = event as? StreamEventStatusUpdate {
      if let originalIndex = statuses.firstIndex(where: { $0.id == event.status.id }) {
        statuses[originalIndex] = event.status
        statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
      }
    }
  }

  func displayPendingStatuses() {
    guard timeline == .home else { return }
    pendingStatuses = pendingStatuses.filter { status in
      !statuses.contains(where: { $0.id == status.id })
    }
    statuses.insert(contentsOf: pendingStatuses, at: 0)
    pendingStatuses = []
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }

  func dequeuePendingStatuses() {
    guard timeline == .home else { return }
    if pendingStatuses.count > 1 {
      let status = pendingStatuses.removeLast()
      statuses.insert(status, at: 0)
    }
    statusesState = .display(statuses: statuses, nextPageState: .hasNextPage)
  }
}
