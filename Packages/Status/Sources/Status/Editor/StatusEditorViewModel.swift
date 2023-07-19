import Combine
import DesignSystem
import Env
import Models
import NaturalLanguage
import Network
import PhotosUI
import SwiftUI

@MainActor
public class StatusEditorViewModel: NSObject, ObservableObject {
  var mode: Mode

  var client: Client?
  var currentAccount: Account? {
    didSet {
      if let itemsProvider {
        mediasImages = []
        processItemsProvider(items: itemsProvider)
      }
    }
  }

  var theme: Theme?
  var preferences: UserPreferences?
  var languageConfirmationDialogLanguages: (detected: String, selected: String)?

  var textView: UITextView? {
    didSet {
      textView?.pasteDelegate = self
    }
  }

  var selectedRange: NSRange {
    get {
      guard let textView else {
        return .init(location: 0, length: 0)
      }
      return textView.selectedRange
    }
    set {
      textView?.selectedRange = newValue
    }
  }

  var markedTextRange: UITextRange? {
    guard let textView else {
      return nil
    }
    return textView.markedTextRange
  }

  @Published var statusText = NSMutableAttributedString(string: "") {
    didSet {
      let range = selectedRange
      processText()
      checkEmbed()
      textView?.attributedText = statusText
      selectedRange = range
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

  private var itemsProvider: [NSItemProvider]?

  @Published var backupStatusText: NSAttributedString?

  @Published var showPoll: Bool = false
  @Published var pollVotingFrequency = PollVotingFrequency.oneVote
  @Published var pollDuration = Duration.oneDay
  @Published var pollOptions: [String] = ["", ""]

  @Published var spoilerOn: Bool = false
  @Published var spoilerText: String = ""

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
    !selectedMedias.isEmpty
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
  private var suggestedTask: Task<Void, Never>?

  init(mode: Mode) {
    self.mode = mode
  }

  func setInitialLanguageSelection(preference: String?) {
    switch mode {
    case let .edit(status), let .quote(status):
      selectedLanguage = status.language
    default:
      break
    }

    selectedLanguage = selectedLanguage ?? preference ?? currentAccount?.source?.language
  }

  func evaluateLanguages() {
    if let detectedLang = detectLanguage(text: statusText.string),
       let selectedLanguage = selectedLanguage,
       selectedLanguage != "",
       selectedLanguage != detectedLang
    {
      languageConfirmationDialogLanguages = (detected: detectedLang, selected: selectedLanguage)
    } else {
      languageConfirmationDialogLanguages = nil
    }
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
                            language: selectedLanguage,
                            mediaAttributes: mediaAttributes)
      switch mode {
      case .new, .replyTo, .quote, .mention, .shareExtension:
        postStatus = try await client.post(endpoint: Statuses.postStatus(json: data))
      case let .edit(status):
        postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id, json: data))
      }
      HapticManager.shared.fireHaptic(of: .notification(.success))
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
      HapticManager.shared.fireHaptic(of: .notification(.error))
      return nil
    }
  }

  // MARK: - Status Text manipulations

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

  func prepareStatusText() {
    switch mode {
    case let .new(visibility):
      self.visibility = visibility
    case let .shareExtension(items):
      itemsProvider = items
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
      if !mentionString.isEmpty {
        mentionString += " "
      }
      replyToStatus = status
      visibility = UserPreferences.shared.getReplyVisibility(of: status)
      statusText = .init(string: mentionString)
      selectedRange = .init(location: mentionString.utf16.count, length: 0)
      if !mentionString.isEmpty {
        self.mentionString = mentionString.trimmingCharacters(in: .whitespaces)
      }
      if !status.spoilerText.asRawText.isEmpty {
        spoilerOn = true
        spoilerText = status.spoilerText.asRawText
      }
    case let .mention(account, visibility):
      statusText = .init(string: "@\(account.acct) ")
      self.visibility = visibility
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
    case let .edit(status):
      var rawText = status.content.asRawText.escape()
      for mention in status.mentions {
        rawText = rawText.replacingOccurrences(of: "@\(mention.username)", with: "@\(mention.acct)")
      }
      statusText = .init(string: rawText)
      selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      spoilerOn = !status.spoilerText.asRawText.isEmpty
      spoilerText = status.spoilerText.asRawText
      visibility = status.visibility
      mediasImages = status.mediaAttachments.map { .init(image: nil,
                                                         movieTransferable: nil,
                                                         gifTransferable: nil,
                                                         mediaAttachment: $0,
                                                         error: nil) }
    case let .quote(status):
      embeddedStatus = status
      if let url = embeddedStatusURL {
        statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
        selectedRange = .init(location: 0, length: 0)
      }
    }
  }

  private func processText() {
    guard markedTextRange == nil else { return }
    statusText.addAttributes([.foregroundColor: UIColor(Theme.shared.labelColor),
                              .font: Font.scaledBodyUIFont,
                              .backgroundColor: UIColor.clear,
                              .underlineColor: UIColor.clear],
                             range: NSMakeRange(0, statusText.string.utf16.count))
    let hashtagPattern = "(#+[\\w0-9(_)]{1,})"
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
        numUrls += 1
        totalUrlLength += range.length

        statusText.addAttributes([.foregroundColor: UIColor(theme?.tintColor ?? .brand),
                                  .underlineStyle: NSUnderlineStyle.single.rawValue,
                                  .underlineColor: UIColor(theme?.tintColor ?? .brand)],
                                 range: NSRange(location: range.location, length: range.length))
      }

      urlLengthAdjustments = totalUrlLength - (maxLengthOfUrl * numUrls)

      statusText.enumerateAttributes(in: range) { attributes, range, _ in
        if attributes[.link] != nil {
          statusText.removeAttribute(.link, range: range)
        }
      }
    } catch {}
  }

  // MARK: - Shar sheet / Item provider

  func processURLs(urls: [URL]) {
    isMediasLoading = true
    let items = urls.filter { $0.startAccessingSecurityScopedResource() }
      .compactMap { NSItemProvider(contentsOf: $0) }
    processItemsProvider(items: items)
  }

  func processCameraPhoto(image: UIImage) {
    mediasImages.append(.init(image: image,
                              movieTransferable: nil,
                              gifTransferable: nil,
                              mediaAttachment: nil,
                              error: nil))
    processMediasToUpload()
  }

  private func processItemsProvider(items: [NSItemProvider]) {
    Task {
      var initialText: String = ""
      for item in items {
        if let identifier = item.registeredTypeIdentifiers.first,
           let handledItemType = StatusEditorUTTypeSupported(rawValue: identifier)
        {
          do {
            let compressor = StatusEditorCompressor()
            let content = try await handledItemType.loadItemContent(item: item)
            if let text = content as? String {
              initialText += "\(text) "
            } else if let image = content as? UIImage {
              mediasImages.append(.init(image: image,
                                        movieTransferable: nil,
                                        gifTransferable: nil,
                                        mediaAttachment: nil,
                                        error: nil))
            } else if let content = content as? ImageFileTranseferable,
                      let compressedData = await compressor.compressImageFrom(url: content.url),
                      let image = UIImage(data: compressedData)
            {
              mediasImages.append(.init(image: image,
                                        movieTransferable: nil,
                                        gifTransferable: nil,
                                        mediaAttachment: nil,
                                        error: nil))
            } else if let video = content as? MovieFileTranseferable {
              mediasImages.append(.init(image: nil,
                                        movieTransferable: video,
                                        gifTransferable: nil,
                                        mediaAttachment: nil,
                                        error: nil))
            } else if let gif = content as? GifFileTranseferable {
              mediasImages.append(.init(image: nil,
                                        movieTransferable: nil,
                                        gifTransferable: gif,
                                        mediaAttachment: nil,
                                        error: nil))
            }
          } catch {
            isMediasLoading = false
          }
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
    suggestedTask?.cancel()
    suggestedTask = Task {
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
          guard !Task.isCancelled else {
            return
          }
          withAnimation {
            tagsSuggestions = results?.hashtags.sorted(by: { $0.totalUses > $1.totalUses }) ?? []
          }
        case "@":
          query.removeFirst()
          results = try await client.get(endpoint: Search.search(query: query,
                                                                 type: "accounts",
                                                                 offset: 0,
                                                                 following: true),
                                         forceVersion: .v2)
          guard !Task.isCancelled else {
            return
          }
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

  func runOpenAI(prompt: OpenAIClient.Prompt) async {
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

        if file == nil {
          file = try? await media.loadTransferable(type: GifFileTranseferable.self)
        }
        if file == nil {
          file = try? await media.loadTransferable(type: MovieFileTranseferable.self)
        }
        if file == nil {
          file = try? await media.loadTransferable(type: ImageFileTranseferable.self)
        }

        let compressor = StatusEditorCompressor()
        if let imageFile = file as? ImageFileTranseferable,
           let compressedData = await compressor.compressImageFrom(url: imageFile.url),
           let image = UIImage(data: compressedData)
        {
          medias.append(.init(image: image,
                              movieTransferable: nil,
                              gifTransferable: nil,
                              mediaAttachment: nil,
                              error: nil))
        } else if let videoFile = file as? MovieFileTranseferable {
          medias.append(.init(image: nil,
                              movieTransferable: videoFile,
                              gifTransferable: nil,
                              mediaAttachment: nil,
                              error: nil))
        } else if let gifFile = file as? GifFileTranseferable {
          medias.append(.init(image: nil,
                              movieTransferable: nil,
                              gifTransferable: gifFile,
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
      guard originalContainer.mediaAttachment == nil else { return }
      let newContainer = StatusEditorMediaContainer(image: originalContainer.image,
                                                    movieTransferable: originalContainer.movieTransferable,
                                                    gifTransferable: nil,
                                                    mediaAttachment: nil,
                                                    error: nil)
      mediasImages[index] = newContainer
      do {
        let compressor = StatusEditorCompressor()
        if let image = originalContainer.image {
          let imageData = try await compressor.compressImageForUpload(image)
          let uploadedMedia = try await uploadMedia(data: imageData, mimeType: "image/jpeg")
          if let index = indexOf(container: newContainer) {
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        movieTransferable: nil,
                                        gifTransferable: nil,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
          }
          if let uploadedMedia, uploadedMedia.url == nil {
            scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
          }
        } else if let videoURL = originalContainer.movieTransferable?.url,
                  let compressedVideoURL = await compressor.compressVideo(videoURL),
                  let data = try? Data(contentsOf: compressedVideoURL)
        {
          let uploadedMedia = try await uploadMedia(data: data, mimeType: compressedVideoURL.mimeType())
          if let index = indexOf(container: newContainer) {
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        movieTransferable: originalContainer.movieTransferable,
                                        gifTransferable: nil,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
          }
          if let uploadedMedia, uploadedMedia.url == nil {
            scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
          }
        } else if let gifData = originalContainer.gifTransferable?.data {
          let uploadedMedia = try await uploadMedia(data: gifData, mimeType: "image/gif")
          if let index = indexOf(container: newContainer) {
            mediasImages[index] = .init(image: mode.isInShareExtension ? originalContainer.image : nil,
                                        movieTransferable: nil,
                                        gifTransferable: originalContainer.gifTransferable,
                                        mediaAttachment: uploadedMedia,
                                        error: nil)
          }
          if let uploadedMedia, uploadedMedia.url == nil {
            scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
          }
        }
      } catch {
        if let index = indexOf(container: newContainer) {
          mediasImages[index] = .init(image: originalContainer.image,
                                      movieTransferable: nil,
                                      gifTransferable: nil,
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
                                                                                             json: .init(description: nil)))
            if newAttachement.url != nil {
              let oldContainer = mediasImages[index]
              mediasImages[index] = .init(image: oldContainer.image,
                                          movieTransferable: oldContainer.movieTransferable,
                                          gifTransferable: oldContainer.gifTransferable,
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
                                                                                json: .init(description: description)))
        mediasImages[index] = .init(image: nil,
                                    movieTransferable: nil,
                                    gifTransferable: nil,
                                    mediaAttachment: media,
                                    error: nil)
      } catch { print(error) }
    }
  }

  private var mediaAttributes: [StatusData.MediaAttribute] = []
  func editDescription(container: StatusEditorMediaContainer, description: String) async {
    guard let attachment = container.mediaAttachment else { return }
    if indexOf(container: container) != nil {
      mediaAttributes.append(StatusData.MediaAttribute(id: attachment.id, description: description, thumbnail: nil, focus: nil))
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

// MARK: - DropDelegate

extension StatusEditorViewModel: DropDelegate {
  public func performDrop(info: DropInfo) -> Bool {
    let item = info.itemProviders(for: StatusEditorUTTypeSupported.types())
    processItemsProvider(items: item)
    return true
  }
}

// MARK: - UITextPasteDelegate

extension StatusEditorViewModel: UITextPasteDelegate {
  public func textPasteConfigurationSupporting(
    _: UITextPasteConfigurationSupporting,
    transform item: UITextPasteItem
  ) {
    if !item.itemProvider.registeredContentTypes(conformingTo: .image).isEmpty ||
      !item.itemProvider.registeredContentTypes(conformingTo: .video).isEmpty ||
      !item.itemProvider.registeredContentTypes(conformingTo: .gif).isEmpty
    {
      processItemsProvider(items: [item.itemProvider])
      item.setNoResult()
    } else {
      item.setDefaultResult()
    }
  }
}
