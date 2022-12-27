import SwiftUI
import DesignSystem
import Models
import Network
import PhotosUI

@MainActor
public class StatusEditorViewModel: ObservableObject {
  struct ImageContainer: Identifiable {
    let id = UUID().uuidString
    let image: UIImage?
    let mediaAttachement: MediaAttachement?
    let error: Error?
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
  
  private var uploadTask: Task<Void, Never>?
    
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
                                                                         mediaIds: mediasImages.compactMap{ $0.mediaAttachement?.id },
                                                                         spoilerText: nil))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id,
                                                                        status: statusText.string,
                                                                        mediaIds:  mediasImages.compactMap{ $0.mediaAttachement?.id },
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
    self.mediasImages = []
    
    Task {
      var medias: [ImageContainer] = []
      for media in selectedMedias {
        do {
          if let data = try await media.loadTransferable(type: Data.self),
            let image = UIImage(data: data) {
            medias.append(.init(image: image, mediaAttachement: nil, error: nil))
          }
        } catch {
          medias.append(.init(image: nil, mediaAttachement: nil, error: error))
        }
      }
      DispatchQueue.main.async { [weak self] in
        self?.mediasImages = medias
        self?.processUpload()
      }
    }
  }
  
  private func processUpload() {
    uploadTask?.cancel()
    let mediasCopy = mediasImages
    uploadTask = Task {
      for (index, media) in mediasCopy.enumerated() {
        do {
          if !Task.isCancelled,
              let data = media.image?.pngData(),
             let uploadedMedia = try await uploadMedia(data: data) {
            mediasImages[index] = .init(image: nil, mediaAttachement: uploadedMedia, error: nil)
          }
        } catch {
          mediasImages[index] = .init(image: nil, mediaAttachement: nil, error: error)
        }
      }
    }
  }
   
  private func uploadMedia(data: Data) async throws -> MediaAttachement? {
    guard let client else { return nil }
    do {
      return try await client.mediaUpload(mimeType: "image/png", data: data)
    } catch {
      return nil
    }
  }
}
