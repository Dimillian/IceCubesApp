import Foundation

public struct ServerError: Decodable, Error {
  public let error: String?
  public var httpCode: Int?
}

extension ServerError: Sendable {}
