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
  
  @Published var selectedRange: NSRange = .init(location: 0, length: 0)
  
  @Published var isPosting: Bool = false
  @Published var selectedMedias: [PhotosPickerItem] = [] {
    didSet {
      if selectedMedias.count > 4 {
        selectedMedias = selectedMedias.prefix(4).map{ $0 }
      }
      inflateSelectedMedias()
    }
  }
  @Published var mediasImages: [ImageContainer] = []
  @Published var embededStatus: Status?
  
  @Published var visibility: Models.Visibility = .pub
  
  private var uploadTask: Task<Void, Never>?
    
  init(mode: Mode) {
    self.mode = mode
  }
  
  func insertStatusText(text: String) {
    let string = statusText
    string.mutableString.insert(text, at: selectedRange.location)
    statusText = string
    selectedRange = NSRange(location: selectedRange.location + text.utf16.count, length: 0)
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
                                                                         spoilerText: nil,
                                                                         visibility: visibility))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id,
                                                                        status: statusText.string,
                                                                        mediaIds:  mediasImages.compactMap{ $0.mediaAttachement?.id },
                                                                        spoilerText: nil,
                                                                        visibility: visibility))
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
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
    case let .edit(status):
      statusText = .init(status.content.asSafeAttributedString)
      selectedRange = .init(location: 0, length: 0)
    case let .quote(status):
      self.embededStatus = status
      if let url = status.reblog?.url ?? status.url {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
        selectedRange = .init(location: 0, length: 0)
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
  
  // MARK: - Media related function
  
  private func indexOf(container: ImageContainer) -> Int? {
    mediasImages.firstIndex(where: { $0.id == container.id })
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
      for media in mediasCopy {
        if !Task.isCancelled {
          await upload(container: media)
        }
      }
    }
  }
  
  func upload(container: ImageContainer) async {
    if let index = indexOf(container: container) {
      let originalContainer = mediasImages[index]
      let newContainer = ImageContainer(image: originalContainer.image, mediaAttachement: nil, error: nil)
      mediasImages[index] = newContainer
      do {
        if let data = originalContainer.image?.jpegData(compressionQuality: 0.90) {
          let uploadedMedia = try await uploadMedia(data: data)
          if let index = indexOf(container: newContainer) {
            mediasImages[index] = .init(image: nil, mediaAttachement: uploadedMedia, error: nil)
          }
        }
      } catch {
        if let index = indexOf(container: newContainer) {
          mediasImages[index] = .init(image: originalContainer.image, mediaAttachement: nil, error: error)
        }
      }
    }
  }
   
  private func uploadMedia(data: Data) async throws -> MediaAttachement? {
    guard let client else { return nil }
    return try await client.mediaUpload(mimeType: "image/jpeg", data: data)
  }
}
