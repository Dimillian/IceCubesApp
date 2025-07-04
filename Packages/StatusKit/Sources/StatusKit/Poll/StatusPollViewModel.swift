import Combine
import Models
import NetworkClient
import Observation
import SwiftUI

@MainActor
@Observable public class StatusPollViewModel {
  public var client: MastodonClient?
  public var instance: Instance?

  var poll: Poll
  var votes: [Int] = []
  var showResults: Bool = false

  public init(poll: Poll) {
    self.poll = poll
    votes = poll.ownVotes ?? []
  }

  public func fetchPoll() async {
    guard let client else { return }
    do {
      poll = try await client.get(endpoint: Polls.poll(id: poll.id))
      showResults = poll.ownVotes?.isEmpty == false || poll.expired
      votes = poll.ownVotes ?? []
    } catch {}
  }

  public func postVotes() async {
    guard let client, !poll.expired else { return }
    do {
      poll = try await client.post(endpoint: Polls.vote(id: poll.id, votes: votes))
      withAnimation {
        votes = poll.ownVotes ?? []
        showResults = true
      }
    } catch {}
  }

  public func handleSelection(_ pollIndex: Int) {
    if poll.multiple {
      if let voterIndex = votes.firstIndex(of: pollIndex) {
        votes.remove(at: voterIndex)
      } else {
        votes.append(pollIndex)
      }
    } else {
      votes = [pollIndex]
    }
  }
}
