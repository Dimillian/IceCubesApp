import SwiftUI

public enum StatusAction : String, CaseIterable {
  case none, reply, quote, boost, favorite, bookmark
  
  @MainActor
  public var displayName: LocalizedStringKey {
    switch self {
    case .none:
      return "settings.swipeactions.status.action.none"
    case .reply:
      return "settings.swipeactions.status.action.reply"
    case .quote:
      return "settings.swipeactions.status.action.quote"
    case .boost:
      return "settings.swipeactions.status.action.boost"
    case .favorite:
      return "settings.swipeactions.status.action.favorite"
    case .bookmark:
      return "settings.swipeactions.status.action.bookmark"
    }
  }
  
  public func iconName(isReblogged: Bool = false, isFavorited: Bool = false, isBookmarked: Bool = false)-> String {
    switch self {
    case .none:
      return "slash.circle"
    case .reply:
      return "arrowshape.turn.up.left"
    case .quote:
      return "quote.bubble"
    case .boost:
      return isReblogged ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
    case .favorite:
      return isFavorited ? "star.fill" : "star"
    case .bookmark:
      return isBookmarked ? "bookmark.fill" : "bookmark"
    }
  }
}
