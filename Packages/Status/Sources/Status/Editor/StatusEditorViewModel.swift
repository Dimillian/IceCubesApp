import SwiftUI
import DesignSystem
import Models
import Network
import PhotosUI

@MainActor
public class StatusEditorViewModel: ObservableObject {
  struct ImageContainer: Identifiable {
    let id = UUID().uuidString
    let image: UIImage
  }
  
  var mode: Mode
  let generator = UINotificationFeedbackGenerator()
  
  var client: Client?
  
  @Published var statusText = NSMutableAttributedString(string: "") {
    didSet {
      highlightMeta()
      checkEmbed()
    }
  }
  
  @Published var isPosting: Bool = false
  @Published var selectedMedias: [PhotosPickerItem] = [] {
    didSet {
      inflateSelectedMedias()
    }
  }
  @Published var mediasImages: [ImageContainer] = []
  
  @Published var embededStatus: Status?
    
  init(mode: Mode) {
    self.mode = mode
  }
  
  func postStatus() async -> Status? {
    guard let client else { return nil }
    do {
      isPosting = true
      let postStatus: Status?
      switch mode {
      case .new, .replyTo, .quote:
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
      statusText = .init(string: "@\(status.reblog?.account.acct ?? status.account.acct) ")
    case let .edit(status):
      statusText = .init(status.content.asSafeAttributedString)
    case let .quote(status):
      self.embededStatus = status
      if let url = status.reblog?.url ?? status.url {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
      }
    default:
      break
    }
  }
  
  private func highlightMeta() {
    statusText.addAttributes([.foregroundColor: UIColor(Color.label)],
                                range: NSMakeRange(0, statusText.string.utf16.count))
    let hashtagPattern = "(#+[a-zA-Z0-9(_)]{1,})"
    let mentionPattern = "(@+[a-zA-Z0-9(_).]{1,})"
    let urlPattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"

    do {
      let hashtagRegex = try NSRegularExpression(pattern: hashtagPattern, options: [])
      let mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
      let urlRegex = try NSRegularExpression(pattern: urlPattern, options: [])
      
      var ranges = hashtagRegex.matches(in: statusText.string,
                                    options: [],
                                    range: NSMakeRange(0, statusText.string.utf16.count)).map { $0.range }
      ranges.append(contentsOf: mentionRegex.matches(in: statusText.string,
                                                     options: [],
                                                     range: NSMakeRange(0, statusText.string.utf16.count)).map {$0.range})
      
      let urlRanges = urlRegex.matches(in: statusText.string,
                                       options: [],
                                       range: NSMakeRange(0, statusText.string.utf16.count)).map { $0.range }

      for range in ranges {
        statusText.addAttributes([.foregroundColor: UIColor(Color.brand)],
                                   range: NSRange(location: range.location, length: range.length))
      }
      
      for range in urlRanges {
        statusText.addAttributes([.foregroundColor: UIColor(Color.brand),
                                     .underlineStyle: NSUnderlineStyle.single,
                                     .underlineColor: UIColor(Color.brand)],
                                    range: NSRange(location: range.location, length: range.length))
      }
    } catch {
      
    }
  }
  
  private func checkEmbed() {
    if let embededStatus, !statusText.string.contains(embededStatus.reblog?.id ?? embededStatus.id) {
      self.embededStatus = nil
      self.mode = .new
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
