import Models
import SwiftUI

public extension Models.Visibility {
  static var supportDefault: [Self] {
    [.pub, .priv, .unlisted]
  }

  var iconName: String {
    switch self {
    case .pub:
      return "globe.americas"
    case .unlisted:
      return "lock.open"
    case .priv:
      return "lock"
    case .direct:
      return "tray.full"
    }
  }

  var title: LocalizedStringKey {
    switch self {
    case .pub:
      return "status.visibility.public"
    case .unlisted:
      return "status.visibility.unlisted"
    case .priv:
      return "status.visibility.follower"
    case .direct:
      return "status.visibility.direct"
    }
  }
}
