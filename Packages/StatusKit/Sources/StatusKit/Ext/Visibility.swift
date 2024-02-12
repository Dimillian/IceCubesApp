import Models
import SwiftUI

public extension Models.Visibility {
  static var supportDefault: [Self] {
    [.pub, .priv, .unlisted]
  }

  var iconName: String {
    switch self {
    case .pub:
      "globe.americas"
    case .unlisted:
      "lock.open"
    case .priv:
      "lock"
    case .direct:
      "tray.full"
    }
  }

  var title: LocalizedStringKey {
    switch self {
    case .pub:
      "status.visibility.public"
    case .unlisted:
      "status.visibility.unlisted"
    case .priv:
      "status.visibility.follower"
    case .direct:
      "status.visibility.direct"
    }
  }
}
