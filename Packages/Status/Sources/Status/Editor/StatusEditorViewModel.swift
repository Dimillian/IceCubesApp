import SwiftUI
import DesignSystem
import Models
import Network
import PhotosUI

@MainActor
public class StatusEditorViewModel: ObservableObject {
  public enum Mode {
    case replyTo(status: Status)
    case new
    case edit(status: Status)
    
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
        return "Reply to \(status.account.displayName)"
      }
    }
  }
  
  let mode: Mode
  
  @Published var statusText = NSAttributedString(string: "") {
    didSet {
      guard !internalUpdate else { return }
      highlightMeta()
    }
  }
  
  @Published var isPosting: Bool = false
  @Published var selectedMedias: [PhotosPickerItem] = [] {
    didSet {
      inflateSelectedMedias()
    }
  }
  @Published var mediasImages: [ImageContainer] = []
  
  struct ImageContainer: Identifiable {
    let id = UUID().uuidString
    let image: UIImage
  }
  
  var client: Client?
  private var internalUpdate: Bool = false
  
  let generator = UINotificationFeedbackGenerator()
  
  init(mode: Mode) {
    self.mode = mode
  }
  
  func postStatus() async -> Status? {
    guard let client else { return nil }
    do {
      isPosting = true
      let postStatus: Status?
      switch mode {
      case .new, .replyTo:
        postStatus = try await client.post(endpoint: Statuses.postStatus(status: statusText.string,
                                                                         inReplyTo: mode.replyToStatus?.id,
                                                                         mediaIds: nil,
                                                                         spoilerText: nil))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id,
                                                                        status: statusText.string,
                                                                        mediaIds: nil,
                                                                        spoilerText: nil))
      }
      generator.notificationOccurred(.success)
      isPosting = false
      return postStatus
    } catch {
      isPosting = false
      generator.notificationOccurred(.error)
      return nil
    }
  }
  
  func prepareStatusText() {
    switch mode {
    case let .replyTo(status):
      statusText = .init(string: "@\(status.account.acct) ")
    case let .edit(status):
      statusText = .init(string: status.content.asRawText)
    default:
      break
    }
  }
  
  func highlightMeta() {
    let mutableString = NSMutableAttributedString(string: statusText.string)
    mutableString.addAttributes([.foregroundColor: UIColor(Color.label)],
                                range: NSMakeRange(0, mutableString.string.utf16.count))
    let hashtagPattern = "(#+[a-zA-Z0-9(_)]{1,})"
    let mentionPattern = "(@+[a-zA-Z0-9(_).]{1,})"
    var ranges: [NSRange] = [NSRange]()

    do {
      let hashtagRegex = try NSRegularExpression(pattern: hashtagPattern, options: [])
      let mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
      
      ranges = hashtagRegex.matches(in: mutableString.string,
                                    options: [],
                                    range: NSMakeRange(0, mutableString.string.utf16.count)).map { $0.range }
      ranges.append(contentsOf: mentionRegex.matches(in: mutableString.string,
                                                     options: [],
                                                     range: NSMakeRange(0, mutableString.string.utf16.count)).map {$0.range})

      for range in ranges {
        mutableString.addAttributes([.foregroundColor: UIColor(Color.brand)],
                                   range: NSRange(location: range.location, length: range.length))
      }
      internalUpdate = true
      statusText = mutableString
      internalUpdate = false
    } catch {
      
    }
  }
  
  func inflateSelectedMedias() {
    for media in selectedMedias {
      media.loadTransferable(type: Data.self) { [weak self] result in
        switch result {
        case .success(let data?):
          if let image = UIImage(data: data) {
            DispatchQueue.main.async {
              self?.mediasImages.append(.init(image: image))
            }
          }
        default:
          break
        }
      }
    }
  }
   
}
