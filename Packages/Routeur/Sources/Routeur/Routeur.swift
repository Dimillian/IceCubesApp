import Foundation
import SwiftUI
import Models

public enum RouteurDestinations: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case statusDetail(id: String)
}

public class RouterPath: ObservableObject {
  @Published public var path: [RouteurDestinations] = []
  
  public init() {}
  
  public func navigate(to: RouteurDestinations) {
    path.append(to)
  }
  
  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if let mention = status.mentions.first(where: { $0.url == url }) {
      navigate(to: .accountDetail(id: mention.id))
      return .handled
    }
    return .systemAction
  }
}
