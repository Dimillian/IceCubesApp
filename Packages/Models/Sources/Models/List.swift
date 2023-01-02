import Foundation

public struct List: Decodable, Identifiable, Equatable, Hashable {
  public let id: String
  public let title: String
  public let repliesPolicy: String
}
