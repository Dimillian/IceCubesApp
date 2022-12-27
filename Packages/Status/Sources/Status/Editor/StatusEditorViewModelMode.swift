import Models

extension StatusEditorViewModel {
  public enum Mode {
    case replyTo(status: Status)
    case new
    case edit(status: Status)
    case quote(status: Status)
    
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
      case .new:
        return "New Post"
      case .edit:
        return "Edit your post"
      case let .replyTo(status):
        return "Reply to \(status.reblog?.account.displayName ?? status.account.displayName)"
      case let .quote(status):
        return "Quote of \(status.reblog?.account.displayName ?? status.account.displayName)"
      }
    }
  }
}
