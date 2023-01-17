import SwiftUI
import DesignSystem
import Env
import Models
import Network
import PhotosUI

@MainActor
public class StatusEditorViewModel: ObservableObject {
  struct ImageContainer: Identifiable {
    let id = UUID().uuidString
    let image: UIImage?
    let mediaAttachment: MediaAttachment?
    let error: Error?
  }
  
  var mode: Mode
  let generator = UINotificationFeedbackGenerator()
  
  var client: Client?
  var currentAccount: Account?
  var theme: Theme?
  
  @Published var statusText = NSMutableAttributedString(string: "") {
    didSet {
      processText()
      checkEmbed()
    }
  }
  @Published var backupStatusText: NSAttributedString?

  @Published var showPoll: Bool = false
  @Published var pollVotingFrequency = PollVotingFrequency.oneVote
  @Published var pollDuration = PollDuration.oneDay
  @Published var pollOptions: [String] = ["", ""]

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
  @Published var embeddedStatus: Status?
  var canPost: Bool {
    statusText.length > 0 || !mediasImages.isEmpty
  }

  var shouldDisablePollButton: Bool {
    showPoll || !selectedMedias.isEmpty
  }
  
  @Published var visibility: Models.Visibility = .pub
  
  @Published var mentionsSuggestions: [Account] = []
  @Published var tagsSuggestions: [Tag] = []
  @Published var selectedLanguage: String?
  private var currentSuggestionRange: NSRange?
  
  private var embeddedStatusURL: URL? {
    return embeddedStatus?.reblog?.url ?? embeddedStatus?.url
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
  
  func replaceTextWith(text: String) {
    statusText = .init(string: text)
    selectedRange = .init(location: text.utf16.count, length: 0)
  }
  
  func setInitialLanguageSelection(preference: String?) {
    switch mode {
    case .replyTo(let status), .edit(let status):
      selectedLanguage = status.language
    default:
      break
    }
    
    selectedLanguage = selectedLanguage ?? preference ?? currentAccount?.source?.language
  }

  private func getPollOptionsForAPI() -> [String]? {
    let options = pollOptions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    return options.isEmpty ? nil : options
  }
  
  func postStatus() async -> Status? {
    guard let client else { return nil }
    do {
      isPosting = true
      let postStatus: Status?
      var pollData: StatusData.PollData?
      if let pollOptions = getPollOptionsForAPI() {
        pollData = .init(options: pollOptions,
                         multiple: pollVotingFrequency.canVoteMultipleTimes,
                         expires_in: pollDuration.rawValue)
      }
      let data = StatusData(status: statusText.string,
                            visibility: visibility,
                            inReplyToId: mode.replyToStatus?.id,
                            spoilerText: spoilerOn ? spoilerText : nil,
                            mediaIds: mediasImages.compactMap{ $0.mediaAttachment?.id },
                            poll: pollData,
                            language: selectedLanguage)
      switch mode {
      case .new, .replyTo, .quote, .mention, .shareExtension:
        postStatus = try await client.post(endpoint: Statuses.postStatus(json: data))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id, json: data))
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
    case let .shareExtension(items):
      self.visibility = .pub
      self.processItemsProvider(items: items)
    case let .replyTo(status):
      var mentionString = ""
      if (status.reblog?.account.acct ?? status.account.acct) != currentAccount?.acct {
        mentionString = "@\(status.reblog?.account.acct ?? status.account.acct)"
      }
      for mention in status.mentions where mention.acct != currentAccount?.acct {
        if !mentionString.isEmpty {
          mentionString += " "
        }
        mentionString += "@\(mention.acct)"
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
      var rawText = NSAttributedString(status.content.asMarkdown.asSafeAttributedString).string
      for mention in status.mentions {
        rawText = rawText.replacingOccurrences(of: "@\(mention.username)", with: "@\(mention.acct)")
      }
      statusText = .init(string: rawText)
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      spoilerOn = !status.spoilerText.isEmpty
      spoilerText = status.spoilerText
      visibility = status.visibility
      mediasImages = status.mediaAttachments.map{ .init(image: nil, mediaAttachment: $0, error: nil )}
    case let .quote(status):
      self.embeddedStatus = status
      if let url = embeddedStatusURL {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
        selectedRange = .init(location: 0, length: 0)
      }
    }
  }
  
  private func processText() {
    statusText.addAttributes([.foregroundColor: UIColor(Color.label)],
                                range: NSMakeRange(0, statusText.string.utf16.count))
    let hashtagPattern = "(#+[a-zA-Z0-9(_)]{1,})"
    let mentionPattern = "(@+[a-zA-Z0-9(_).-]{1,})"
    let urlPattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"

    do {
      let hashtagRegex = try NSRegularExpression(pattern: hashtagPattern, options: [])
      let mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
      let urlRegex = try NSRegularExpression(pattern: urlPattern, options: [])
      
      let range = NSMakeRange(0, statusText.string.utf16.count)
      var ranges = hashtagRegex.matches(in: statusText.string,
                                    options: [],
                                    range: range).map { $0.range }
      ranges.append(contentsOf: mentionRegex.matches(in: statusText.string,
                                                     options: [],
                                                     range: range).map {$0.range})
      
      let urlRanges = urlRegex.matches(in: statusText.string,
                                       options: [],
                                       range:range).map { $0.range }

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
      
      var attachmentsToRemove: [NSRange] = []
      statusText.enumerateAttribute(.attachment, in: range) { attachment, range, _ in
        if let attachment = attachment as? NSTextAttachment, let image = attachment.image {
          attachmentsToRemove.append(range)
          mediasImages.append(.init(image: image, mediaAttachment: nil, error: nil))
        }
      }
      if !attachmentsToRemove.isEmpty {
        processMediasToUpload()
        for range in attachmentsToRemove {
          statusText.removeAttribute(.attachment, range: range)
        }
      }
    } catch {
      
    }
  }
  
  private func processItemsProvider(items: [NSItemProvider]) {
    Task {
      var initialText: String = ""
      for item in items {
        if let identifier = item.registeredTypeIdentifiers.first,
           let handledItemType = StatusEditorUTTypeSupported(rawValue: identifier) {
          do {
            let content = try await handledItemType.loadItemContent(item: item)
            if let text = content as? String {
              initialText += "\(text) "
            } else if let image = content as? UIImage {
              mediasImages.append(.init(image: image, mediaAttachment: nil, error: nil))
            }
          } catch { }
        }
      }
      if !initialText.isEmpty {
        statusText = .init(string: initialText)
        selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      }
      if !mediasImages.isEmpty {
        processMediasToUpload()
      }
    }
  }

  func resetPollDefaults() {
    pollOptions = ["", ""]
    pollDuration = .oneDay
    pollVotingFrequency = .oneVote
  }
  
  private func checkEmbed() {
    if let url = embeddedStatusURL,
        !statusText.string.contains(url.absoluteString) {
      self.embeddedStatus = nil
      self.mode = .new(visibilty: visibility)
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
  
  // MARK: - OpenAI Prompt
  func runOpenAI(prompt: OpenAIClient.Prompts) async {
    do {
      let client = OpenAIClient()
      let response = try await client.request(prompt)
      if var text = response.choices.first?.text {
        text.removeFirst()
        text.removeFirst()
        backupStatusText = statusText
        replaceTextWith(text: text)
      }
    } catch { }
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
            medias.append(.init(image: image, mediaAttachment: nil, error: nil))
          }
        } catch {
          medias.append(.init(image: nil, mediaAttachment: nil, error: error))
        }
      }
      DispatchQueue.main.async { [weak self] in
        self?.mediasImages = medias
        self?.processMediasToUpload()
      }
    }
  }
  
  private func processMediasToUpload() {
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
      let newContainer = ImageContainer(image: originalContainer.image, mediaAttachment: nil, error: nil)
      mediasImages[index] = newContainer
      do {
        if let data = originalContainer.image?.jpegData(compressionQuality: 0.90) {
          let uploadedMedia = try await uploadMedia(data: data)
          if let index = indexOf(container: newContainer) {
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
          }
        }
      } catch {
        if let index = indexOf(container: newContainer) {
          mediasImages[index] = .init(image: originalContainer.image, mediaAttachment: nil, error: error)
        }
      }
    }
  }
  
  func addDescription(container: ImageContainer, description: String) async {
    guard let client, let attachment = container.mediaAttachment else { return }
    if let index = indexOf(container: container) {
      do {
        let media: MediaAttachment = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                 description: description))
        mediasImages[index] = .init(image: nil, mediaAttachment: media, error: nil)
      } catch {
        
      }
    }
  }
   
  private func uploadMedia(data: Data) async throws -> MediaAttachment? {
    guard let client else { return nil }
    return try await client.mediaUpload(endpoint: Media.medias,
                                        version: .v2,
                                        method: "POST",
                                        mimeType: "image/jpeg",
                                        filename: "file",
                                        data: data)
  }
}
