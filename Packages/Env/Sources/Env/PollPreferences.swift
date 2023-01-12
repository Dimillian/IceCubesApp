import Foundation

public enum PollDuration: Int, CaseIterable {
  // rawValue == time in seconds; used for sending to the API
  case fiveMinutes = 300
  case halfAnHour = 1800
  case oneHour = 3600
  case sixHours = 21600
  case oneDay = 86400
  case threeDays = 259_200
  case sevenDays = 604_800

  public var displayString: String {
    switch self {
    case .fiveMinutes: return "5 minutes"
    case .halfAnHour: return "30 minutes"
    case .oneHour: return "1 hour"
    case .sixHours: return "6 hours"
    case .oneDay: return "1 day"
    case .threeDays: return "3 days"
    case .sevenDays: return "7 days"
    }
  }
}

public enum PollVotingFrequency: String, CaseIterable {
  case oneVote = "One Vote"
  case multipleVotes = "Multiple Votes"

  public var canVoteMultipleTimes: Bool {
    switch self {
    case .multipleVotes: return true
    case .oneVote: return false
    }
  }
}
