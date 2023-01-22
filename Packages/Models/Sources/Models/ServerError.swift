import Foundation

public struct ServerError: Decodable, Error {
  public let error: String?
}
