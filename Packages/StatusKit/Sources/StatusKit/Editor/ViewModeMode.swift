import Models
import SwiftUI
import UIKit

public extension StatusEditor.ViewModel {
  enum Mode {
    case replyTo(status: Status)
    case new(visibility: Models.Visibility)
    case edit(status: Status)
    case quote(status: Status)
    case quoteLink(link: URL)
    case mention(account: Account, visibility: Models.Visibility)
    case shareExtension(items: [NSItemProvider])

    var isInShareExtension: Bool {
      switch self {
      case .shareExtension:
        true
      default:
        false
      }
    }

    var isEditing: Bool {
      switch self {
      case .edit:
        true
      default:
        false
      }
    }

    var replyToStatus: Status? {
      switch self {
      case let .replyTo(status):
        status
      default:
        nil
      }
    }

    var title: LocalizedStringKey {
      switch self {
      case .new, .mention, .shareExtension, .quoteLink:
        "status.editor.mode.new"
      case .edit:
        "status.editor.mode.edit"
      case let .replyTo(status):
        "status.editor.mode.reply-\(status.reblog?.account.displayNameWithoutEmojis ?? status.account.displayNameWithoutEmojis)"
      case let .quote(status):
        "status.editor.mode.quote-\(status.reblog?.account.displayNameWithoutEmojis ?? status.account.displayNameWithoutEmojis)"
      }
    }
  }
}
