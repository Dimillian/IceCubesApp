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
  var currentAccount: Account?
  var theme: Theme?
  
  @Published var statusText = NSMutableAttributedString(string: "") {
    didSet {
      highlightMeta()
      checkEmbed()
    }
  }
  
  @Published var spoilerOn: Bool = false
  @Published var spoilerText: String = ""
  
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
  @Published var replyToStatus: Status?
  @Published var embededStatus: Status?
  var canPost: Bool {
    statusText.length > 0 || !selectedMedias.isEmpty
  }
  
  @Published var visibility: Models.Visibility = .pub
  
  @Published var mentionsSuggestions: [Account] = []
  @Published var tagsSuggestions: [Tag] = []
  private var currentSuggestionRange: NSRange?
  
  private var embededStatusURL: URL? {
    return embededStatus?.reblog?.url ?? embededStatus?.url
  }
  
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
  
  func replaceTextWith(text: String, inRange: NSRange) {
    let string = statusText
    string.mutableString.deleteCharacters(in: inRange)
    string.mutableString.insert(text, at: inRange.location)
    statusText = string
    selectedRange = NSRange(location: inRange.location + text.utf16.count, length: 0)
  }
  
  func postStatus() async -> Status? {
    guard let client else { return nil }
    do {
      isPosting = true
      let postStatus: Status?
      switch mode {
      case .new, .replyTo, .quote, .mention:
        postStatus = try await client.post(endpoint: Statuses.postStatus(status: statusText.string,
                                                                         inReplyTo: mode.replyToStatus?.id,
                                                                         mediaIds: mediasImages.compactMap{ $0.mediaAttachement?.id },
                                                                         spoilerText: spoilerOn ? spoilerText : nil,
                                                                         visibility: visibility))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id,
                                                                        status: statusText.string,
                                                                        mediaIds:  mediasImages.compactMap{ $0.mediaAttachement?.id },
                                                                        spoilerText: spoilerOn ? spoilerText : nil,
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
    case let .new(visibility):
      self.visibility = visibility
    case let .replyTo(status):
      var mentionString = ""
      if (status.reblog?.account.acct ?? status.account.acct) != currentAccount?.acct {
        mentionString = "@\(status.reblog?.account.acct ?? status.account.acct)"
      }
      for mention in status.mentions where mention.acct != currentAccount?.acct {
        mentionString += " @\(mention.acct)"
      }
      mentionString += " "
      replyToStatus = status
      visibility = status.visibility
      statusText = .init(string: mentionString)
      selectedRange = .init(location: mentionString.utf16.count, length: 0)
    case let .mention(account, visibility):
      statusText = .init(string: "@\(account.acct) ")
      self.visibility = visibility
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
    case let .edit(status):
      statusText = .init(status.content.asSafeAttributedString)
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      spoilerOn = !status.spoilerText.isEmpty
      spoilerText = status.spoilerText
      visibility = status.visibility
      mediasImages = status.mediaAttachments.map{ .init(image: nil, mediaAttachement: $0, error: nil )}
    case let .quote(status):
      self.embededStatus = status
      if let url = embededStatusURL {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
        selectedRange = .init(location: 0, length: 0)
      }
    }
  }
  
  private func highlightMeta() {
    statusText.addAttributes([.foregroundColor: UIColor(Color.label)],
                                range: NSMakeRange(0, statusText.string.utf16.count))
    let hashtagPattern = "(#+[a-zA-Z0-9(_)]{1,})"
    let mentionPattern = "(@+[a-zA-Z0-9(_).-]{1,})"
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

      var foundSuggestionRange: Bool = false
      for nsRange in ranges {
        statusText.addAttributes([.foregroundColor: UIColor(theme?.tintColor ?? .brand)],
                                   range: nsRange)
        if selectedRange.location == (nsRange.location + nsRange.length),
           let range = Range(nsRange, in: statusText.string) {
          foundSuggestionRange = true
          currentSuggestionRange = nsRange
          loadAutoCompleteResults(query: String(statusText.string[range]))
        }
      }
      
      if !foundSuggestionRange || ranges.isEmpty{
        resetAutoCompletion()
      }
      
      for range in urlRanges {
        statusText.addAttributes([.foregroundColor: UIColor(theme?.tintColor ?? .brand),
                                     .underlineStyle: NSUnderlineStyle.single,
                                  .underlineColor: UIColor(theme?.tintColor ?? .brand)],
                                    range: NSRange(location: range.location, length: range.length))
      }
    } catch {
      
    }
  }
  
  private func checkEmbed() {
    if let url = embededStatusURL,
        !statusText.string.contains(url.absoluteString) {
      self.embededStatus = nil
      self.mode = .new(vivibilty: visibility)
    }
  }
  
  // MARK: - Autocomplete
  
  private func loadAutoCompleteResults(query: String) {
    guard let client, query.utf8.count > 1 else { return }
    Task {
      do {
        var results: SearchResults?
        switch query.first {
        case "#":
          results = try await client.get(endpoint: Search.search(query: query,
                                                                 type: "hashtags",
                                                                 offset: 0,
                                                                 following: nil),
                                         forceVersion: .v2)
          withAnimation {
            tagsSuggestions = results?.hashtags ?? []
          }
        case "@":
          results = try await client.get(endpoint: Search.search(query: query,
                                                                 type: "accounts",
                                                                 offset: 0,
                                                                 following: true),
                                         forceVersion: .v2)
          withAnimation {
            mentionsSuggestions = results?.accounts ?? []
          }
          break
        default:
          break
        }
      } catch {
        
      }
    }
  }
  
  private func resetAutoCompletion() {
    tagsSuggestions = []
    mentionsSuggestions = []
    currentSuggestionRange = nil
  }
  
  func selectMentionSuggestion(account: Account) {
    if let range = currentSuggestionRange {
      replaceTextWith(text: "@\(account.acct) ", inRange: range)
    }
  }
  
  func selectHashtagSuggestion(tag: Tag) {
    if let range = currentSuggestionRange {
      replaceTextWith(text: "#\(tag.name) ", inRange: range)
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
  
  func addDescription(container: ImageContainer, description: String) async {
    guard let client, let attachment = container.mediaAttachement else { return }
    if let index = indexOf(container: container) {
      do {
        let media: MediaAttachement = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                 description: description))
        mediasImages[index] = .init(image: nil, mediaAttachement: media, error: nil)
      } catch {
        
      }
    }
  }
   
  private func uploadMedia(data: Data) async throws -> MediaAttachement? {
    guard let client else { return nil }
    return try await client.mediaUpload(endpoint: Media.medias,
                                        version: .v2,
                                        method: "POST",
                                        mimeType: "image/jpeg",
                                        filename: "file",
                                        data: data)
  }
}
