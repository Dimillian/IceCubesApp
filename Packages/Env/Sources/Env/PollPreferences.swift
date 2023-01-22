import Foundation
import SwiftUI

public enum PollDuration: Int, CaseIterable {
  // rawValue == time in seconds; used for sending to the API
  case fiveMinutes = 300
  case halfAnHour = 1800
  case oneHour = 3600
  case sixHours = 21600
  case oneDay = 86400
  case threeDays = 259_200
  case sevenDays = 604_800

  public var displayString: LocalizedStringKey {
    switch self {
    case .fiveMinutes: return "env.poll-duration.5m"
    case .halfAnHour: return "env.poll-duration.30m"
    case .oneHour: return "env.poll-duration.1h"
    case .sixHours: return "env.poll-duration.6h"
    case .oneDay: return "env.poll-duration.1d"
    case .threeDays: return "env.poll-duration.3d"
    case .sevenDays: return "env.poll-duration.7d"
    }
  }
}

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
