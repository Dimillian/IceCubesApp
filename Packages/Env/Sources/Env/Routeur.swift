import Foundation
import SwiftUI
import Models
import Network

public enum RouteurDestinations: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case statusDetail(id: String)
  case hashTag(tag: String, account: String?)
  case followers(id: String)
  case following(id: String)
  case favouritedBy(id: String)
  case rebloggedBy(id: String)
}

public enum SheetDestinations: Identifiable {
  case newStatusEditor
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  
  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor:
      return "statusEditor"
    }
  }
}

public class RouterPath: ObservableObject {
  public var client: Client?
  
  @Published public var path: [RouteurDestinations] = []
  @Published public var presentedSheet: SheetDestinations?
  
  public init() {}
  
  public func navigate(to: RouteurDestinations) {
    path.append(to)
  }
  
  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if url.pathComponents.contains(where: { $0 == "tags" }),
        let tag = url.pathComponents.last {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if let mention = status.mentions.first(where: { $0.url == url }) {
      navigate(to: .accountDetail(id: mention.id))
      return .handled
    } else if let client = client,
              let id = status.content.findStatusesIds(instance: client.server)?.first(where: { String($0) == url.lastPathComponent}) {
      navigate(to: .statusDetail(id: String(id)))
      return .handled
    }
    return .systemAction
  }
  
  public func handle(url: URL) -> OpenURLAction.Result {
    if url.pathComponents.contains(where: { $0 == "tags" }),
        let tag = url.pathComponents.last {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    }
    return .systemAction
  }
}
