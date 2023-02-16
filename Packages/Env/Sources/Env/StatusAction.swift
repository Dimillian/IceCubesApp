import SwiftUI

public enum StatusAction: String, CaseIterable, Identifiable {
  public var id: String {
    "\(rawValue)"
  }

  case none, reply, boost, favorite, bookmark, quote

  public func displayName(isReblogged: Bool = false, isFavorited: Bool = false, isBookmarked: Bool = false) -> LocalizedStringKey {
    switch self {
    case .none:
      return "settings.swipeactions.status.action.none"
    case .reply:
      return "settings.swipeactions.status.action.reply"
    case .quote:
      return "settings.swipeactions.status.action.quote"
    case .boost:
      return isReblogged ? "status.action.unboost" : "settings.swipeactions.status.action.boost"
    case .favorite:
      return isFavorited ? "status.action.unfavorite" : "settings.swipeactions.status.action.favorite"
    case .bookmark:
      return isBookmarked ? "status.action.unbookmark" : "settings.swipeactions.status.action.bookmark"
    }
  }

  public func iconName(isReblogged: Bool = false, isFavorited: Bool = false, isBookmarked: Bool = false) -> String {
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

  public func color(themeTintColor: Color, useThemeColor: Bool, outside: Bool) -> Color {
    if (useThemeColor) {
      return outside ? themeTintColor : .gray
    }
    
    switch self {
    case .none:
      return .gray
    case .reply:
      return outside ? .gray : Color(white: 0.45)
    case .quote:
      return outside ? .gray : Color(white: 0.45)
    case .boost:
      return themeTintColor
    case .favorite:
      return .yellow
    case .bookmark:
      return .pink
    }
  }
}
