import Foundation
import Models

public enum Collections: Endpoint {
  case accountCollections(id: String)
  case collection(id: String)
  case accountInCollections(id: String)

  public func path() -> String {
    switch self {
    case .accountCollections(let id):
      "accounts/\(id)/collections"
    case .collection(let id):
      "collections/\(id)"
    case .accountInCollections(let id):
      "accounts/\(id)/in_collections"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
