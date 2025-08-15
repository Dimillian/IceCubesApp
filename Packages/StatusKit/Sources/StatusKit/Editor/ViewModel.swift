import Combine
import DesignSystem
import Env
import Models
import NaturalLanguage
import NetworkClient
import PhotosUI
import SwiftUI

#if !targetEnvironment(macCatalyst)
  import FoundationModels
#endif
import AVFoundation

extension StatusEditor {
  @MainActor
  @Observable public class ViewModel: NSObject, Identifiable {
    public let id = UUID()

    var mode: Mode

    var client: MastodonClient?
    var currentAccount: Account? {
      didSet {
        if itemsProvider != nil {
          mediaContainers = []
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

    var statusText = NSMutableAttributedString(string: "") {
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

    var backupStatusText: NSAttributedString?

    var showPoll: Bool = false
    var pollVotingFrequency = PollVotingFrequency.oneVote
    var pollDuration = Duration.oneDay
    var pollOptions: [String] = ["", ""]

    var spoilerOn: Bool = false
    var spoilerText: String = ""

    var postingProgress: Double = 0.0
    var postingTimer: Timer?
    var isPosting: Bool = false

    var mediaPickers: [PhotosPickerItem] = [] {
      didSet {
        if mediaPickers.count > 4 {
          mediaPickers = mediaPickers.prefix(4).map { $0 }
        }

        let removedIDs =
          oldValue
          .filter { !mediaPickers.contains($0) }
          .compactMap(\.itemIdentifier)
        mediaContainers.removeAll { removedIDs.contains($0.id) }

        let newPickerItems = mediaPickers.filter { !oldValue.contains($0) }
        if !newPickerItems.isEmpty {
          isMediasLoading = true
          for item in newPickerItems {
            prepareToPost(for: item)
          }
        }
      }
    }

    var isMediasLoading: Bool = false

    var mediaContainers: [MediaContainer] = []
    var replyToStatus: Status?
    var embeddedStatus: Status?

    var customEmojiContainer: [CategorizedEmojiContainer] = []

    var postingError: String?
    var showPostingErrorAlert: Bool = false

    var canPost: Bool {
      statusText.length > 0 || !mediaContainers.isEmpty
    }

    var shouldDisablePollButton: Bool {
      !mediaContainers.isEmpty
    }

    var allMediaHasDescription: Bool {
      var everyMediaHasAltText = true
      for mediaContainer in mediaContainers {
        if ((mediaContainer.mediaAttachment?.description) == nil)
          || mediaContainer.mediaAttachment?.description?.count == 0
        {
          everyMediaHasAltText = false
        }
      }

      return everyMediaHasAltText
    }

    var shouldDisplayDismissWarning: Bool {
      var modifiedStatusText = statusText.string.trimmingCharacters(in: .whitespaces)

      if let mentionString, modifiedStatusText.hasPrefix(mentionString) {
        modifiedStatusText = String(modifiedStatusText.dropFirst(mentionString.count))
      }

      return !modifiedStatusText.isEmpty && !mode.isInShareExtension
    }

    // Map of container.id -> initial alt text (from intents)
    var containerIdToAltText: [String: String] = [:]

    var visibility: Models.Visibility = .pub

    var mentionsSuggestions: [Account] = []
    var tagsSuggestions: [Tag] = []
    var showRecentsTagsInline: Bool = false
    var selectedLanguage: String?
    var hasExplicitlySelectedLanguage: Bool = false
    private var currentSuggestionRange: NSRange?

    private var embeddedStatusURL: URL? {
      URL(string: embeddedStatus?.reblog?.url ?? embeddedStatus?.url ?? "")
    }

    private var mentionString: String?

    private var suggestedTask: Task<Void, Never>?

    init(mode: Mode) {
      self.mode = mode

      #if !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *), Assistant.isAvailable {
          Assistant.prewarm()
        }
      #endif
    }

    func setInitialLanguageSelection(preference: String?) {
      switch mode {
      case .edit(let status), .quote(let status):
        selectedLanguage = status.language
      default:
        break
      }

      selectedLanguage = selectedLanguage ?? preference ?? currentAccount?.source?.language
    }

    func evaluateLanguages() {
      if let detectedLang = detectLanguage(text: statusText.string),
        let selectedLanguage,
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
        if !allMediaHasDescription && UserPreferences.shared.appRequireAltText {
          throw PostError.missingAltText
        }

        if postingTimer == nil {
          Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
              if self.postingProgress < 100 {
                self.postingProgress += 0.5
              }
              if self.postingProgress >= 100 {
                self.postingTimer?.invalidate()
                self.postingTimer = nil
              }
            }
          }
        }
        isPosting = true
        let postStatus: Status?
        var pollData: StatusData.PollData?
        if let pollOptions = getPollOptionsForAPI() {
          pollData = .init(
            options: pollOptions,
            multiple: pollVotingFrequency.canVoteMultipleTimes,
            expires_in: pollDuration.rawValue)
        }
        let data = StatusData(
          status: statusText.string,
          visibility: visibility,
          inReplyToId: mode.replyToStatus?.id,
          spoilerText: spoilerOn ? spoilerText : nil,
          mediaIds: mediaContainers.compactMap { $0.mediaAttachment?.id },
          poll: pollData,
          language: selectedLanguage,
          mediaAttributes: mediaAttributes)
        switch mode {
        case .new, .replyTo, .quote, .mention, .shareExtension, .quoteLink, .imageURL:
          postStatus = try await client.post(endpoint: Statuses.postStatus(json: data))
          if let postStatus {
            StreamWatcher.shared.emmitPostEvent(for: postStatus)
          }
        case .edit(let status):
          postStatus = try await client.put(
            endpoint: Statuses.editStatus(id: status.id, json: data))
          if let postStatus {
            StreamWatcher.shared.emmitEditEvent(for: postStatus)
          }
        }

        postingTimer?.invalidate()
        postingTimer = nil

        withAnimation {
          postingProgress = 99.0
        }
        try await Task.sleep(for: .seconds(0.5))
        HapticManager.shared.fireHaptic(.notification(.success))

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
        if let postError = error as? PostError {
          postingError = postError.description
          showPostingErrorAlert = true
        }
        isPosting = false
        HapticManager.shared.fireHaptic(.notification(.error))
        return nil
      }
    }

    // MARK: - Status Text manipulations

    func insertStatusText(text: String) {
      let string = statusText
      string.mutableString.insert(text, at: selectedRange.location)
      statusText = string
      selectedRange = NSRange(location: selectedRange.location + text.utf16.count, length: 0)
      processText()
    }

    func replaceTextWith(text: String, inRange: NSRange) {
      let string = statusText
      string.mutableString.deleteCharacters(in: inRange)
      string.mutableString.insert(text, at: inRange.location)
      statusText = string
      selectedRange = NSRange(location: inRange.location + text.utf16.count, length: 0)
      if let textView {
        textView.delegate?.textViewDidChange?(textView)
      }
    }

    func replaceTextWith(text: String) {
      statusText = .init(string: text)
      selectedRange = .init(location: text.utf16.count, length: 0)
    }

    func prepareStatusText() {
      switch mode {
      case .new(let text, let visibility):
        if let text {
          statusText = .init(string: text)
          selectedRange = .init(location: text.utf16.count, length: 0)
        }
        self.visibility = visibility
      case .shareExtension(let items):
        itemsProvider = items
        visibility = .pub
        processItemsProvider(items: items)
      case .imageURL(let urls, let caption, let altTexts, let visibility):
        Task {
          let containers = await Self.makeImageContainer(from: urls)
          if let altTexts {
            for (i, c) in containers.enumerated() where i < altTexts.count {
              let desc = altTexts[i].trimmingCharacters(in: .whitespacesAndNewlines)
              if !desc.isEmpty {
                containerIdToAltText[c.id] = desc
              }
            }
          }
          for container in containers {
            prepareToPost(for: container)
          }
        }
        if let caption, !caption.isEmpty {
          statusText = .init(string: caption)
          selectedRange = .init(location: caption.utf16.count, length: 0)
        }
        self.visibility = visibility
      case .replyTo(let status):
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
      case .mention(let account, let visibility):
        statusText = .init(string: "@\(account.acct) ")
        self.visibility = visibility
        selectedRange = .init(location: statusText.string.utf16.count, length: 0)
      case .edit(let status):
        var rawText = status.content.asRawText.escape()
        for mention in status.mentions {
          rawText = rawText.replacingOccurrences(
            of: "@\(mention.username)", with: "@\(mention.acct)")
        }
        statusText = .init(string: rawText)
        selectedRange = .init(location: statusText.string.utf16.count, length: 0)
        spoilerOn = !status.spoilerText.asRawText.isEmpty
        spoilerText = status.spoilerText.asRawText
        visibility = status.visibility
        mediaContainers = status.mediaAttachments.map {
          MediaContainer.uploaded(
            id: UUID().uuidString,
            attachment: $0,
            originalImage: nil
          )
        }
      case .quote(let status):
        embeddedStatus = status
        if let url = embeddedStatusURL {
          statusText = .init(
            string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
          selectedRange = .init(location: 0, length: 0)
        }
      case .quoteLink(let link):
        statusText = .init(string: "\n\n\(link)")
        selectedRange = .init(location: 0, length: 0)
      }
    }

    private func processText() {
      guard markedTextRange == nil else { return }
      statusText.addAttributes(
        [
          .foregroundColor: UIColor(Theme.shared.labelColor),
          .font: Font.scaledBodyUIFont,
          .backgroundColor: UIColor.clear,
          .underlineColor: UIColor.clear,
        ],
        range: NSMakeRange(0, statusText.string.utf16.count))
      let hashtagPattern = "(#+[\\w0-9(_)]{0,})"
      let mentionPattern = "(@+[a-zA-Z0-9(_).-]{1,})"
      let urlPattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"

      do {
        let hashtagRegex = try NSRegularExpression(pattern: hashtagPattern, options: [])
        let mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
        let urlRegex = try NSRegularExpression(pattern: urlPattern, options: [])

        let range = NSMakeRange(0, statusText.string.utf16.count)
        var ranges = hashtagRegex.matches(
          in: statusText.string,
          options: [],
          range: range
        ).map(\.range)
        ranges.append(
          contentsOf: mentionRegex.matches(
            in: statusText.string,
            options: [],
            range: range
          ).map(\.range))

        let urlRanges = urlRegex.matches(
          in: statusText.string,
          options: [],
          range: range
        ).map(\.range)

        var foundSuggestionRange = false
        for nsRange in ranges {
          statusText.addAttributes(
            [.foregroundColor: UIColor(theme?.tintColor ?? .brand)],
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

          statusText.addAttributes(
            [
              .foregroundColor: UIColor(theme?.tintColor ?? .brand),
              .underlineStyle: NSUnderlineStyle.single.rawValue,
              .underlineColor: UIColor(theme?.tintColor ?? .brand),
            ],
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

    func processGIFData(data: Data) {
      isMediasLoading = true
      let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
      try? data.write(to: url)
      let container = MediaContainer.pending(
        id: UUID().uuidString,
        gif: .init(url: url),
        preview: nil)
      prepareToPost(for: container)
    }

    func processCameraPhoto(image: UIImage) {
      let container = MediaContainer.pending(
        id: UUID().uuidString,
        image: image
      )
      prepareToPost(for: container)
    }

    private func processItemsProvider(items: [NSItemProvider]) {
      Task {
        var initialText: String = ""
        for item in items {
          if let identifier = item.registeredTypeIdentifiers.first {
            let handledItemType = UTTypeSupported(value: identifier)
            do {
              let compressor = Compressor()
              let content = try await handledItemType.loadItemContent(item: item)
              if let text = content as? String {
                initialText += "\(text) "
              } else if let image = content as? UIImage {
                let container = MediaContainer.pending(
                  id: UUID().uuidString,
                  image: image
                )
                prepareToPost(for: container)
              } else if let content = content as? ImageFileTranseferable,
                let compressedData = await compressor.compressImageFrom(url: content.url),
                let image = UIImage(data: compressedData)
              {
                let container = MediaContainer.pending(
                  id: UUID().uuidString,
                  image: image
                )
                prepareToPost(for: container)
              } else if let video = content as? MovieFileTranseferable {
                let container = MediaContainer.pending(
                  id: UUID().uuidString,
                  video: video,
                  preview: await Self.extractVideoPreview(from: video.url)
                )
                prepareToPost(for: container)
              } else if let gif = content as? GifFileTranseferable {
                let container = MediaContainer.pending(
                  id: UUID().uuidString,
                  gif: gif,
                  preview: nil
                )
                prepareToPost(for: container)
              }
            } catch {
              isMediasLoading = false
            }
          }
        }
        if !initialText.isEmpty {
          statusText = .init(string: "\n\n\(initialText)")
          selectedRange = .init(location: 0, length: 0)
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
        mode = .new(text: nil, visibility: visibility)
      }
    }

    // MARK: - Autocomplete

    private func loadAutoCompleteResults(query: String) {
      guard let client else { return }
      var query = query
      suggestedTask?.cancel()
      suggestedTask = Task {
        do {
          var results: SearchResults?
          switch query.first {
          case "#":
            if query.utf8.count == 1 {
              withAnimation {
                showRecentsTagsInline = true
              }
              return
            }
            showRecentsTagsInline = false
            query.removeFirst()
            results = try await client.get(
              endpoint: Search.search(
                query: query,
                type: .hashtags,
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
            guard query.utf8.count > 1 else { return }
            query.removeFirst()
            let accounts: [Account] = try await client.get(
              endpoint: Search.accountsSearch(
                query: query,
                type: nil,
                offset: 0,
                following: nil),
              forceVersion: .v1)
            guard !Task.isCancelled else {
              return
            }
            withAnimation {
              mentionsSuggestions = accounts
            }
          default:
            break
          }
        } catch {}
      }
    }

    private func resetAutoCompletion() {
      if !tagsSuggestions.isEmpty || !mentionsSuggestions.isEmpty || currentSuggestionRange != nil
        || showRecentsTagsInline
      {
        withAnimation {
          tagsSuggestions = []
          mentionsSuggestions = []
          currentSuggestionRange = nil
          showRecentsTagsInline = false
        }
      }
    }

    func selectMentionSuggestion(account: Account) {
      if let range = currentSuggestionRange {
        replaceTextWith(text: "@\(account.acct) ", inRange: range)
      }
    }

    func selectHashtagSuggestion(tag: String) {
      if let range = currentSuggestionRange {
        var tag = tag
        if tag.hasPrefix("#") {
          tag.removeFirst()
        }
        replaceTextWith(text: "#\(tag) ", inRange: range)
      }
    }

    // MARK: - Assistant Prompt

    @available(iOS 26.0, *)
    func runAssistant(prompt: AIPrompt) async {
      #if !targetEnvironment(macCatalyst)
        let assistant = Assistant()
        var newStream: LanguageModelSession.ResponseStream<String>?
        switch prompt {
        case .correct:
          newStream = await assistant.correct(message: statusText.string)
        case .emphasize:
          newStream = await assistant.emphasize(message: statusText.string)
        case .fit:
          newStream = await assistant.shorten(message: statusText.string)
        case .rewriteWithTone(let tone):
          newStream = await assistant.adjustTone(message: statusText.string, to: tone)
        }

        if let newStream {
          backupStatusText = statusText
          do {
            for try await content in newStream {
              replaceTextWith(text: content.content)
            }
          } catch {
            if let backupStatusText {
              replaceTextWith(text: backupStatusText.string)
            }
          }
        }
      #endif
    }

    // MARK: - Media related function

    private func indexOf(container: MediaContainer) -> Int? {
      mediaContainers.firstIndex(where: { $0.id == container.id })
    }

    func prepareToPost(for pickerItem: PhotosPickerItem) {
      Task(priority: .high) {
        if let container = await makeMediaContainer(from: pickerItem) {
          self.mediaContainers.append(container)
          await upload(container: container)
          self.isMediasLoading = false
        }
      }
    }

    func prepareToPost(for container: MediaContainer) {
      Task(priority: .high) {
        self.mediaContainers.append(container)
        await upload(container: container)
        if let desc = containerIdToAltText[container.id], !desc.isEmpty {
          await addDescription(container: container, description: desc)
          containerIdToAltText.removeValue(forKey: container.id)
        }
        self.isMediasLoading = false
      }
    }

    nonisolated func makeMediaContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer?
    {
      await withTaskGroup(of: MediaContainer?.self, returning: MediaContainer?.self) { taskGroup in
        taskGroup.addTask(priority: .high) { await Self.makeImageContainer(from: pickerItem) }
        taskGroup.addTask(priority: .high) { await Self.makeGifContainer(from: pickerItem) }
        taskGroup.addTask(priority: .high) { await Self.makeMovieContainer(from: pickerItem) }

        for await container in taskGroup {
          if let container {
            taskGroup.cancelAll()
            return container
          }
        }

        return nil
      }
    }

    private static func makeGifContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer?
    {
      guard let gifFile = try? await pickerItem.loadTransferable(type: GifFileTranseferable.self)
      else { return nil }

      // Try to extract a preview image from the GIF
      let previewImage: UIImage? = nil // GIFs typically show animated preview
      
      return MediaContainer.pending(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        gif: gifFile,
        preview: previewImage
      )
    }

    private static func makeMovieContainer(from pickerItem: PhotosPickerItem) async
      -> MediaContainer?
    {
      guard
        let movieFile = try? await pickerItem.loadTransferable(type: MovieFileTranseferable.self)
      else { return nil }

      // Extract preview frame from video
      let previewImage = await extractVideoPreview(from: movieFile.url)
      
      return MediaContainer.pending(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        video: movieFile,
        preview: previewImage
      )
    }

    private static func makeImageContainer(from pickerItem: PhotosPickerItem) async
      -> MediaContainer?
    {
      guard
        let imageFile = try? await pickerItem.loadTransferable(type: ImageFileTranseferable.self)
      else { return nil }

      let compressor = Compressor()

      guard let compressedData = await compressor.compressImageFrom(url: imageFile.url),
        let image = UIImage(data: compressedData)
      else { return nil }

      return MediaContainer.pending(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        image: image
      )
    }

    private static func makeImageContainer(from urls: [URL]) async -> [MediaContainer] {
      var containers: [MediaContainer] = []

      for url in urls {
        let compressor = Compressor()
        _ = url.startAccessingSecurityScopedResource()
        if let compressedData = await compressor.compressImageFrom(url: url),
          let image = UIImage(data: compressedData)
        {
          containers.append(
            MediaContainer.pending(
              id: UUID().uuidString,
              image: image
            )
          )
        }

        url.stopAccessingSecurityScopedResource()
      }

      return containers
    }
    
    private static func extractVideoPreview(from url: URL) async -> UIImage? {
      let asset = AVURLAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      
      return await withCheckedContinuation { continuation in
        generator.generateCGImageAsynchronously(for: .zero) { cgImage, _, error in
          if let cgImage = cgImage {
            continuation.resume(returning: UIImage(cgImage: cgImage))
          } else {
            continuation.resume(returning: nil)
          }
        }
      }
    }

    func upload(container: MediaContainer) async {
      guard let index = indexOf(container: container) else { return }
      let originalContainer = mediaContainers[index]
      
      // Only upload if in pending state
      guard case .pending(let content) = originalContainer.state else { return }
      
      // Set to uploading state
      mediaContainers[index] = MediaContainer(
        id: originalContainer.id,
        state: .uploading(content: content, progress: 0.0)
      )
      
      do {
        let compressor = Compressor()
        let uploadedMedia: MediaAttachment?
        
        switch content {
        case .image(let image):
          let imageData = try await compressor.compressImageForUpload(image)
          uploadedMedia = try await uploadMedia(data: imageData, mimeType: "image/jpeg") { [weak self] progress in
            guard let self else { return }
            Task { @MainActor in
              if let index = self.indexOf(container: originalContainer) {
                self.mediaContainers[index] = MediaContainer(
                  id: originalContainer.id,
                  state: .uploading(content: content, progress: progress)
                )
              }
            }
          }
          
        case .video(let transferable, _):
          let videoURL = transferable.url
          guard let compressedVideoURL = await compressor.compressVideo(videoURL),
                let data = try? Data(contentsOf: compressedVideoURL)
          else {
            throw MediaContainer.MediaError.compressionFailed
          }
          uploadedMedia = try await uploadMedia(data: data, mimeType: compressedVideoURL.mimeType()) { [weak self] progress in
            guard let self else { return }
            Task { @MainActor in
              if let index = self.indexOf(container: originalContainer) {
                self.mediaContainers[index] = MediaContainer(
                  id: originalContainer.id,
                  state: .uploading(content: content, progress: progress)
                )
              }
            }
          }
          
        case .gif(let transferable, _):
          guard let gifData = transferable.data else {
            throw MediaContainer.MediaError.compressionFailed
          }
          uploadedMedia = try await uploadMedia(data: gifData, mimeType: "image/gif") { [weak self] progress in
            guard let self else { return }
            Task { @MainActor in
              if let index = self.indexOf(container: originalContainer) {
                self.mediaContainers[index] = MediaContainer(
                  id: originalContainer.id,
                  state: .uploading(content: content, progress: progress)
                )
              }
            }
          }
        }
        
        if let index = indexOf(container: originalContainer),
           let uploadedMedia {
          // Update to uploaded state
          mediaContainers[index] = MediaContainer.uploaded(
            id: originalContainer.id,
            attachment: uploadedMedia,
            originalImage: mode.isInShareExtension ? content.previewImage : nil
          )
          
          // Schedule refresh if URL is not ready
          if uploadedMedia.url == nil {
            scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
          }
        }
      } catch {
        if let index = indexOf(container: originalContainer) {
          // Update to failed state
          let mediaError: MediaContainer.MediaError
          if let serverError = error as? ServerError {
            mediaError = .uploadFailed(serverError)
          } else {
            mediaError = .compressionFailed
          }
          
          mediaContainers[index] = MediaContainer.failed(
            id: originalContainer.id,
            content: content,
            error: mediaError
          )
        }
      }
    }

    private func scheduleAsyncMediaRefresh(mediaAttachement: MediaAttachment) {
      Task {
        repeat {
          if let client,
            let index = mediaContainers.firstIndex(where: {
              $0.mediaAttachment?.id == mediaAttachement.id
            })
          {
            guard mediaContainers[index].mediaAttachment?.url == nil else {
              return
            }
            do {
              let newAttachement: MediaAttachment = try await client.get(
                endpoint: Media.media(
                  id: mediaAttachement.id,
                  json: nil))
              if newAttachement.url != nil {
                let oldContainer = mediaContainers[index]
                if case .uploaded(_, let originalImage) = oldContainer.state {
                  mediaContainers[index] = MediaContainer.uploaded(
                    id: oldContainer.id,
                    attachment: newAttachement,
                    originalImage: originalImage
                  )
                }
              }
            } catch {}
          }
          try? await Task.sleep(for: .seconds(5))
        } while !Task.isCancelled
      }
    }

    func addDescription(container: MediaContainer, description: String) async {
      guard let client,
            let index = indexOf(container: container)
      else { return }

      let state = mediaContainers[index].state
      guard case .uploaded(let attachment, let originalImage) = state else { return }

      do {
        let media: MediaAttachment = try await client.put(
          endpoint: Media.media(
            id: attachment.id,
            json: .init(description: description)))
        mediaContainers[index] = MediaContainer.uploaded(
          id: mediaContainers[index].id,
          attachment: media,
          originalImage: originalImage
        )
      } catch {}
    }

    private var mediaAttributes: [StatusData.MediaAttribute] = []
    func editDescription(container: MediaContainer, description: String) async {
      guard let attachment = container.mediaAttachment else { return }
      if indexOf(container: container) != nil {
        mediaAttributes.append(
          StatusData.MediaAttribute(
            id: attachment.id, description: description, thumbnail: nil, focus: nil))
      }
    }

    private func uploadMedia(data: Data, mimeType: String, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> MediaAttachment? {
      guard let client else { return nil }
      return try await client.mediaUpload(
        endpoint: Media.medias,
        version: .v2,
        method: "POST",
        mimeType: mimeType,
        filename: "file",
        data: data,
        progressHandler: progressHandler)
    }

    // MARK: - Custom emojis

    func fetchCustomEmojis() async {
      typealias EmojiContainer = CategorizedEmojiContainer

      guard let client else { return }
      do {
        let customEmojis: [Emoji] = try await client.get(endpoint: CustomEmojis.customEmojis) ?? []
        var emojiContainers: [EmojiContainer] = []

        customEmojis.reduce([String: [Emoji]]()) { currentDict, emoji in
          var dict = currentDict
          let category = emoji.category ?? "Custom"

          if let emojis = dict[category] {
            dict[category] = emojis + [emoji]
          } else {
            dict[category] = [emoji]
          }

          return dict
        }.sorted(by: { lhs, rhs in
          if rhs.key == "Custom" {
            false
          } else if lhs.key == "Custom" {
            true
          } else {
            lhs.key < rhs.key
          }
        }).forEach { key, value in
          emojiContainers.append(.init(categoryName: key, emojis: value))
        }

        customEmojiContainer = emojiContainers
      } catch {}
    }
  }
}

// MARK: - DropDelegate

extension StatusEditor.ViewModel: DropDelegate {
  public func performDrop(info: DropInfo) -> Bool {
    let item = info.itemProviders(for: [.image, .video, .gif, .mpeg4Movie, .quickTimeMovie, .movie])
    processItemsProvider(items: item)
    return true
  }
}

// MARK: - UITextPasteDelegate

extension StatusEditor.ViewModel: UITextPasteDelegate {
  public func textPasteConfigurationSupporting(
    _: UITextPasteConfigurationSupporting,
    transform item: UITextPasteItem
  ) {
    if !item.itemProvider.registeredContentTypes(conformingTo: .image).isEmpty
      || !item.itemProvider.registeredContentTypes(conformingTo: .video).isEmpty
      || !item.itemProvider.registeredContentTypes(conformingTo: .gif).isEmpty
    {
      processItemsProvider(items: [item.itemProvider])
      item.setNoResult()
    } else {
      item.setDefaultResult()
    }
  }
}
