import DesignSystem
import Env
import Models
import Network
import PhotosUI
import SwiftUI

@MainActor
public class StatusEditorViewModel: ObservableObject {
  var mode: Mode
  let generator = UINotificationFeedbackGenerator()

  var client: Client?
  var currentAccount: Account?
  var theme: Theme?
  var preferences: UserPreferences?

  @Published var statusText = NSMutableAttributedString(string: "") {
    didSet {
      processText()
      checkEmbed()
    }
  }

  private var urlLengthAdjustments: Int = 0
  private let maxLengthOfUrl = 23

  private var spoilerTextCount: Int {
    spoilerOn ? spoilerText.utf16.count : 0
  }

  var statusTextCharacterLength: Int {
    urlLengthAdjustments - statusText.string.utf16.count - spoilerTextCount
  }

  @Published var backupStatusText: NSAttributedString?

  @Published var showPoll: Bool = false
  @Published var pollVotingFrequency = PollVotingFrequency.oneVote
  @Published var pollDuration = PollDuration.oneDay
  @Published var pollOptions: [String] = ["", ""]

  @Published var spoilerOn: Bool = false
  @Published var spoilerText: String = ""

  @Published var selectedRange: NSRange = .init(location: 0, length: 0)
  @Published var markedTextRange: UITextRange? = nil

  @Published var isPosting: Bool = false
  @Published var selectedMedias: [PhotosPickerItem] = [] {
    didSet {
      if selectedMedias.count > 4 {
        selectedMedias = selectedMedias.prefix(4).map { $0 }
      }
      isMediasLoading = true
      inflateSelectedMedias()
    }
  }

  @Published var isMediasLoading: Bool = false

  @Published var mediasImages: [StatusEditorMediaContainer] = []
  @Published var replyToStatus: Status?
  @Published var embeddedStatus: Status?

  @Published var customEmojis: [Emoji] = []

  @Published var postingError: String?
  @Published var showPostingErrorAlert: Bool = false

  var canPost: Bool {
    statusText.length > 0 || !mediasImages.isEmpty
  }

  var shouldDisablePollButton: Bool {
    showPoll || !selectedMedias.isEmpty
  }

  var shouldDisplayDismissWarning: Bool {
    var modifiedStatusText = statusText.string.trimmingCharacters(in: .whitespaces)

    if let mentionString, modifiedStatusText.hasPrefix(mentionString) {
      modifiedStatusText = String(modifiedStatusText.dropFirst(mentionString.count))
    }

    return !modifiedStatusText.isEmpty && !mode.isInShareExtension
  }

  @Published var visibility: Models.Visibility = .pub

  @Published var mentionsSuggestions: [Account] = []
  @Published var tagsSuggestions: [Tag] = []
  @Published var selectedLanguage: String?
  var hasExplicitlySelectedLanguage: Bool = false
  private var currentSuggestionRange: NSRange?

  private var embeddedStatusURL: URL? {
    URL(string: embeddedStatus?.reblog?.url ?? embeddedStatus?.url ?? "")
  }

  private var mentionString: String?
  private var uploadTask: Task<Void, Never>?

  init(mode: Mode) {
    self.mode = mode
  }

  func setInitialLanguageSelection(preference: String?) {
    switch mode {
    case let .replyTo(status), let .edit(status):
      selectedLanguage = status.language
    default:
      break
    }

    selectedLanguage = selectedLanguage ?? preference ?? currentAccount?.source?.language
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
                            mediaIds: mediasImages.compactMap { $0.mediaAttachment?.id },
                            poll: pollData,
                            language: selectedLanguage)
      switch mode {
      case .new, .replyTo, .quote, .mention, .shareExtension:
        postStatus = try await client.post(endpoint: Statuses.postStatus(json: data))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id, json: data))
      }
      generator.notificationOccurred(.success)
      if hasExplicitlySelectedLanguage, let selectedLanguage {
        preferences?.markLanguageAsSelected(isoCode: selectedLanguage)
      }
      isPosting = false
      return postStatus
    } catch {
      if let error = error as? Models.ServerError {
        postingError = error.error
        showPostingErrorAlert = true
      }
      isPosting = false
      generator.notificationOccurred(.error)
      return nil
    }
  }

  // MARK: - Status Text manipulations

  func insertStatusText(text: String) {
    let string = statusText
    string.mutableString.insert(text, at: selectedRange.location)
    statusText = string
    selectedRange = NSRange(location: selectedRange.location + text.utf16.count, length: 0)
    markedTextRange = nil
  }

  func replaceTextWith(text: String, inRange: NSRange) {
    let string = statusText
    string.mutableString.deleteCharacters(in: inRange)
    string.mutableString.insert(text, at: inRange.location)
    statusText = string
    selectedRange = NSRange(location: inRange.location + text.utf16.count, length: 0)
    markedTextRange = nil
  }

  func replaceTextWith(text: String) {
    statusText = .init(string: text)
    selectedRange = .init(location: text.utf16.count, length: 0)
    markedTextRange = nil
  }

  func prepareStatusText() {
    switch mode {
    case let .new(visibility):
      self.visibility = visibility
    case let .shareExtension(items):
      visibility = .pub
      processItemsProvider(items: items)
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
      markedTextRange = nil
      if !mentionString.isEmpty {
        self.mentionString = mentionString.trimmingCharacters(in: .whitespaces)
      }
    case let .mention(account, visibility):
      statusText = .init(string: "@\(account.acct) ")
      self.visibility = visibility
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      markedTextRange = nil
    case let .edit(status):
      var rawText = NSAttributedString(status.content.asSafeMarkdownAttributedString).string
      for mention in status.mentions {
        rawText = rawText.replacingOccurrences(of: "@\(mention.username)", with: "@\(mention.acct)")
      }
      statusText = .init(string: rawText)
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      markedTextRange = nil
      spoilerOn = !status.spoilerText.asRawText.isEmpty
      spoilerText = status.spoilerText.asRawText
      visibility = status.visibility
      mediasImages = status.mediaAttachments.map { .init(image: nil,
                                                         movieTransferable: nil,
                                                         mediaAttachment: $0,
                                                         error: nil) }
    case let .quote(status):
      embeddedStatus = status
      if let url = embeddedStatusURL {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
        selectedRange = .init(location: 0, length: 0)
        markedTextRange = nil
      }
    }
  }

  private func processText() {
    guard markedTextRange == nil else { return }
    statusText.addAttributes([.foregroundColor: UIColor(Color.label),
                              .backgroundColor: .clear,
                              .underlineColor: .clear],
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
                                                     range: range).map { $0.range })

      let urlRanges = urlRegex.matches(in: statusText.string,
                                       options: [],
                                       range: range).map { $0.range }

      var foundSuggestionRange = false
      for nsRange in ranges {
        statusText.addAttributes([.foregroundColor: UIColor(theme?.tintColor ?? .brand)],
                                 range: nsRange)
        if selectedRange.location == (nsRange.location + nsRange.length),
           let range = Range(nsRange, in: statusText.string)
        {
          foundSuggestionRange = true
          currentSuggestionRange = nsRange
          loadAutoCompleteResults(query: String(statusText.string[range]))
        }
      }

      if !foundSuggestionRange || ranges.isEmpty {
        resetAutoCompletion()
      }

      var totalUrlLength = 0
      var numUrls = 0

      for range in urlRanges {
        if range.length > maxLengthOfUrl {
          numUrls += 1
          totalUrlLength += range.length
        }

        statusText.addAttributes([.foregroundColor: UIColor(theme?.tintColor ?? .brand),
                                  .underlineStyle: NSUnderlineStyle.single.rawValue,
                                  .underlineColor: UIColor(theme?.tintColor ?? .brand)],
                                 range: NSRange(location: range.location, length: range.length))
      }

      urlLengthAdjustments = totalUrlLength - (maxLengthOfUrl * numUrls)

      var mediaAdded = false
      statusText.enumerateAttributes(in: range) { attributes, range, _ in
        if let attachment = attributes[.attachment] as? NSTextAttachment, let image = attachment.image {
          mediasImages.append(.init(image: image,
                                    movieTransferable: nil,
                                    mediaAttachment: nil,
                                    error: nil))
          statusText.removeAttribute(.attachment, range: range)
          statusText.mutableString.deleteCharacters(in: range)
          mediaAdded = true
        } else if attributes[.link] != nil {
          statusText.removeAttribute(.link, range: range)
        }
      }

      if mediaAdded {
        processMediasToUpload()
      }
    } catch {}
  }

  // MARK: - Shar sheet / Item provider

  private func processItemsProvider(items: [NSItemProvider]) {
    Task {
      var initialText: String = ""
      for item in items {
        if let identifier = item.registeredTypeIdentifiers.first,
           let handledItemType = StatusEditorUTTypeSupported(rawValue: identifier)
        {
          do {
            let content = try await handledItemType.loadItemContent(item: item)
            if let text = content as? String {
              initialText += "\(text) "
            } else if let image = content as? UIImage {
              mediasImages.append(.init(image: image,
                                        movieTransferable: nil,
                                        mediaAttachment: nil,
                                        error: nil))
            } else if let video = content as? MovieFileTranseferable {
              mediasImages.append(.init(image: nil,
                                        movieTransferable: video,
                                        mediaAttachment: nil,
                                        error: nil))
            }
          } catch {}
        }
      }
      if !initialText.isEmpty {
        statusText = .init(string: initialText)
        selectedRange = .init(location: statusText.string.utf16.count, length: 0)
        markedTextRange = nil
      }
      if !mediasImages.isEmpty {
        processMediasToUpload()
      }
    }
  }

  // MARK: - Polls

  func resetPollDefaults() {
    pollOptions = ["", ""]
    pollDuration = .oneDay
    pollVotingFrequency = .oneVote
  }

  private func getPollOptionsForAPI() -> [String]? {
    let options = pollOptions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    return options.isEmpty ? nil : options
  }

  // MARK: - Embeds

  private func checkEmbed() {
    if let url = embeddedStatusURL,
       !statusText.string.contains(url.absoluteString)
    {
      embeddedStatus = nil
      mode = .new(visibility: visibility)
    }
  }

  // MARK: - Autocomplete

  private func loadAutoCompleteResults(query: String) {
    guard let client, query.utf8.count > 1 else { return }
    var query = query
    Task {
      do {
        var results: SearchResults?
        switch query.first {
        case "#":
          query.removeFirst()
          results = try await client.get(endpoint: Search.search(query: query,
                                                                 type: "hashtags",
                                                                 offset: 0,
                                                                 following: nil),
                                         forceVersion: .v2)
          withAnimation {
            tagsSuggestions = results?.hashtags ?? []
          }
        case "@":
          query.removeFirst()
          results = try await client.get(endpoint: Search.search(query: query,
                                                                 type: "accounts",
                                                                 offset: 0,
                                                                 following: true),
                                         forceVersion: .v2)
          withAnimation {
            mentionsSuggestions = results?.accounts ?? []
          }
        default:
          break
        }
      } catch {}
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
      backupStatusText = statusText
      replaceTextWith(text: response.trimmedText)
    } catch {}
  }

  // MARK: - Media related function

  private func indexOf(container: StatusEditorMediaContainer) -> Int? {
    mediasImages.firstIndex(where: { $0.id == container.id })
  }

  func inflateSelectedMedias() {
    mediasImages = []

    Task {
      var medias: [StatusEditorMediaContainer] = []
      for media in selectedMedias {
        var file: (any Transferable)?
        do {
          file = try await media.loadTransferable(type: ImageFileTranseferable.self)
          if file == nil {
            file = try await media.loadTransferable(type: MovieFileTranseferable.self)
          }
        } catch {
          medias.append(.init(image: nil,
                              movieTransferable: nil,
                              mediaAttachment: nil,
                              error: error))
        }

        if var imageFile = file as? ImageFileTranseferable,
           let image = imageFile.image
        {
          medias.append(.init(image: image,
                              movieTransferable: nil,
                              mediaAttachment: nil,
                              error: nil))
        } else if let videoFile = file as? MovieFileTranseferable {
          medias.append(.init(image: nil,
                              movieTransferable: videoFile,
                              mediaAttachment: nil,
                              error: nil))
        }
      }

      DispatchQueue.main.async { [weak self] in
        self?.mediasImages = medias
        self?.processMediasToUpload()
      }
    }
  }

  private func processMediasToUpload() {
    isMediasLoading = false
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

  func upload(container: StatusEditorMediaContainer) async {
    if let index = indexOf(container: container) {
      let originalContainer = mediasImages[index]
      let newContainer = StatusEditorMediaContainer(image: originalContainer.image,
                                                    movieTransferable: originalContainer.movieTransferable,
                                                    mediaAttachment: nil,
                                                    error: nil)
      mediasImages[index] = newContainer
      do {
        if let index = indexOf(container: newContainer) {
          if let image = originalContainer.image,
             let data = image.jpegData(compressionQuality: 0.90)
          {
            let uploadedMedia = try await uploadMedia(data: data, mimeType: "image/jpeg")
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        movieTransferable: nil,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
            if let uploadedMedia, uploadedMedia.url == nil {
              scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
            }
          } else if let videoURL = await originalContainer.movieTransferable?.compressedVideoURL,
                    let data = try? Data(contentsOf: videoURL)
          {
            let uploadedMedia = try await uploadMedia(data: data, mimeType: videoURL.mimeType())
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        movieTransferable: originalContainer.movieTransferable,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
            if let uploadedMedia, uploadedMedia.url == nil {
              scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
            }
          }
        }
      } catch {
        if let index = indexOf(container: newContainer) {
          mediasImages[index] = .init(image: originalContainer.image,
                                      movieTransferable: nil,
                                      mediaAttachment: nil,
                                      error: error)
        }
      }
    }
  }

  private func scheduleAsyncMediaRefresh(mediaAttachement: MediaAttachment) {
    Task {
      repeat {
        if let client,
           let index = mediasImages.firstIndex(where: { $0.mediaAttachment?.id == mediaAttachement.id })
        {
          guard mediasImages[index].mediaAttachment?.url == nil else {
            return
          }
          do {
            let newAttachement: MediaAttachment = try await client.get(endpoint: Media.media(id: mediaAttachement.id,
                                                                                             description: nil))
            if newAttachement.url != nil {
              let oldContainer = mediasImages[index]
              mediasImages[index] = .init(image: oldContainer.image,
                                          movieTransferable: oldContainer.movieTransferable,
                                          mediaAttachment: newAttachement,
                                          error: nil)
            }
          } catch {}
        }
        try? await Task.sleep(for: .seconds(5))
      } while !Task.isCancelled
    }
  }

  func addDescription(container: StatusEditorMediaContainer, description: String) async {
    guard let client, let attachment = container.mediaAttachment else { return }
    if let index = indexOf(container: container) {
      do {
        let media: MediaAttachment = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                description: description))
        mediasImages[index] = .init(image: nil,
                                    movieTransferable: nil,
                                    mediaAttachment: media,
                                    error: nil)
      } catch {}
    }
  }

  private func uploadMedia(data: Data, mimeType: String) async throws -> MediaAttachment? {
    guard let client else { return nil }
    return try await client.mediaUpload(endpoint: Media.medias,
                                        version: .v2,
                                        method: "POST",
                                        mimeType: mimeType,
                                        filename: "file",
                                        data: data)
  }

  // MARK: - Custom emojis

  func fetchCustomEmojis() async {
    guard let client else { return }
    do {
      customEmojis = try await client.get(endpoint: CustomEmojis.customEmojis) ?? []
    } catch {}
  }
}

extension StatusEditorViewModel: DropDelegate {
  public func performDrop(info: DropInfo) -> Bool {
    let item = info.itemProviders(for: StatusEditorUTTypeSupported.types())
    processItemsProvider(items: item)
    return true
  }
}
