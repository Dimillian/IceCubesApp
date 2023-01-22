import Models
import Foundation

public struct Digest: Identifiable {
  public var id: String {
    "\(generatedAt)"
  }

  public let generatedAt: String
  public let totalStatuses: Int
}

public extension [Status] {
  func gatherPopular(percentile: Double) -> [Status] {
    var allStatusesScores: [Double] = [];
    for status in self {
      allStatusesScores.append(status.popularity)
    }

    // Calculate the popularity criteria (percentile) based of all statuses metric
    let scores = allStatusesScores.sorted()
    let position = Int(ceil((Double(scores.count) * percentile) / 100)) - 1
    let percentileThreshold = scores[position]

    // Filter out the statuses that are bellow the percentile of acceptance for pupularity
    var popularStatuses: [Status] = []
    for status in self where status.popularity >= percentileThreshold {
      popularStatuses.append(status)
    }
    // Sort for descending popularity (most popular first)
    popularStatuses.sort {
      $0.popularity > $1.popularity
    }

    return popularStatuses
  }
}
