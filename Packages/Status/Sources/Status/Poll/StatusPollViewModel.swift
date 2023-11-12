import Combine
import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable public class StatusPollViewModel {
  public var client: Client?
  public var instance: Instance?

  var poll: Poll
  var votes: [Int] = []

  var showResults: Bool {
    poll.ownVotes?.isEmpty == false || poll.expired
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
