import Foundation

public struct List: Codable, Identifiable, Equatable, Hashable {
  public let id: String
  public let title: String
  public let repliesPolicy: String
}
