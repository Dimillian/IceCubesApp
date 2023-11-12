import Foundation
import SwiftUI

public enum PollVotingFrequency: String, CaseIterable {
  case oneVote = "one-vote"
  case multipleVotes = "multiple-votes"

  public var canVoteMultipleTimes: Bool {
    switch self {
    case .multipleVotes: true
    case .oneVote: false
    }
  }

  public var displayString: LocalizedStringKey {
    switch self {
    case .oneVote: "env.poll-vote-frequency.one"
    case .multipleVotes: "env.poll-vote-frequency.multiple"
    }
  }
}
