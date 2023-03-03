import Foundation
import SwiftUI

public enum PollVotingFrequency: String, CaseIterable {
  case oneVote = "one-vote"
  case multipleVotes = "multiple-votes"

  public var canVoteMultipleTimes: Bool {
    switch self {
    case .multipleVotes: return true
    case .oneVote: return false
    }
  }

  public var displayString: LocalizedStringKey {
    switch self {
    case .oneVote: return "env.poll-vote-frequency.one"
    case .multipleVotes: return "env.poll-vote-frequency.multiple"
    }
  }
}
