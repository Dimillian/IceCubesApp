import Models

extension StatusEditorViewModel {
  public enum Mode {
    case replyTo(status: Status)
    case new(vivibilty: Visibility)
    case edit(status: Status)
    case quote(status: Status)
    case mention(account: Account, visibility: Visibility)
    
    var isEditing: Bool {
      switch self {
      case .edit:
        return true
      default:
        return false
      }
    }
    
    var replyToStatus: Status? {
      switch self {
        case let .replyTo(status):
          return status
        default:
          return nil
      }
    }
    
    var title: String {
      switch self {
      case .new, .mention:
        return "New Post"
      case .edit:
        return "Editing your post"
      case let .replyTo(status):
        return "Replying to \(status.reblog?.account.displayName ?? status.account.displayName)"
      case let .quote(status):
        return "Quote of \(status.reblog?.account.displayName ?? status.account.displayName)"
      }
    }
  }
}
