import Models
import Network
import SwiftUI

@MainActor
public class StatusPollViewModel: ObservableObject {
  public var client: Client?
  public var instance: Instance?

  @Published var poll: Poll
  @Published var votes: [Int] = []

  var showResults: Bool {
    !votes.isEmpty || poll.expired
  }

  public init(poll: Poll) {
    self.poll = poll
    votes = poll.ownVotes ?? []
  }

  public func fetchPoll() async {
    guard let client else { return }
    do {
      poll = try await client.get(endpoint: Polls.poll(id: poll.id))
      votes = poll.ownVotes ?? []
    } catch {}
  }

  public func postVotes() async {
    guard let client, !poll.expired else { return }
    do {
      poll = try await client.post(endpoint: Polls.vote(id: poll.id, votes: votes))
      withAnimation {
        votes = poll.ownVotes ?? []
      }
    } catch {
      print(error)
    }
  }
}
