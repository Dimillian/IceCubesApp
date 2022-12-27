import Foundation
import SwiftUI
import Models

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
  case editStatusEditor(status: AnyStatus)
  case replyToStatusEditor(status: AnyStatus)
  case quoteStatusEditor(status: AnyStatus)
  
  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor:
      return "statusEditor"
    }
  }
}

public class RouterPath: ObservableObject {
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
