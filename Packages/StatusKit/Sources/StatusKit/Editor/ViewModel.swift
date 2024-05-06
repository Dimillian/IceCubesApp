import Combine
import DesignSystem
import Env
import Models
import NaturalLanguage
import Network
import PhotosUI
import SwiftUI

public extension StatusEditor {
  @MainActor
  @Observable class ViewModel: NSObject, Identifiable {
    public let id = UUID()

    var mode: Mode

    var client: Client?
    var currentAccount: Account? {
      didSet {
        if let itemsProvider {
          mediaContainers = []
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

        let removedIDs = oldValue
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
        if ((mediaContainer.mediaAttachment?.description) == nil) ||
          mediaContainer.mediaAttachment?.description?.count == 0
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
          pollData = .init(options: pollOptions,
                           multiple: pollVotingFrequency.canVoteMultipleTimes,
                           expires_in: pollDuration.rawValue)
        }
        let data = StatusData(status: statusText.string,
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
        case let .edit(status):
          postStatus = try await client.put(endpoint: Statuses.editStatus(id: status.id, json: data))
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
    }

    func replaceTextWith(text: String) {
      statusText = .init(string: text)
      selectedRange = .init(location: text.utf16.count, length: 0)
    }

    func prepareStatusText() {
      switch mode {
      case let .new(text, visibility):
        if let text {
          statusText = .init(string: text)
          selectedRange = .init(location: text.utf16.count, length: 0)
        }
        self.visibility = visibility
      case let .shareExtension(items):
        itemsProvider = items
        visibility = .pub
        processItemsProvider(items: items)
      case let .imageURL(urls, visibility):
        Task {
          for container in await Self.makeImageContainer(from: urls) {
            prepareToPost(for: container)
          }
        }
        self.visibility = visibility
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
        mediaContainers = status.mediaAttachments.map {
          MediaContainer(
            id: UUID().uuidString,
            image: nil,
            movieTransferable: nil,
            gifTransferable: nil,
            mediaAttachment: $0,
            error: nil
          )
        }
      case let .quote(status):
        embeddedStatus = status
        if let url = embeddedStatusURL {
          statusText = .init(string: "\n\nFrom: @\(status.reblog?.account.acct ?? status.account.acct)\n\(url)")
          selectedRange = .init(location: 0, length: 0)
        }
      case let .quoteLink(link):
        statusText = .init(string: "\n\n\(link)")
        selectedRange = .init(location: 0, length: 0)
      }
    }

    private func processText() {
      guard markedTextRange == nil else { return }
      statusText.addAttributes([.foregroundColor: UIColor(Theme.shared.labelColor),
                                .font: Font.scaledBodyUIFont,
                                .backgroundColor: UIColor.clear,
                                .underlineColor: UIColor.clear],
                               range: NSMakeRange(0, statusText.string.utf16.count))
      let hashtagPattern = "(#+[\\w0-9(_)]{0,})"
      let mentionPattern = "(@+[a-zA-Z0-9(_).-]{1,})"
      let urlPattern = "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)"

      do {
        let hashtagRegex = try NSRegularExpression(pattern: hashtagPattern, options: [])
        let mentionRegex = try NSRegularExpression(pattern: mentionPattern, options: [])
        let urlRegex = try NSRegularExpression(pattern: urlPattern, options: [])

        let range = NSMakeRange(0, statusText.string.utf16.count)
        var ranges = hashtagRegex.matches(in: statusText.string,
                                          options: [],
                                          range: range).map(\.range)
        ranges.append(contentsOf: mentionRegex.matches(in: statusText.string,
                                                       options: [],
                                                       range: range).map(\.range))

        let urlRanges = urlRegex.matches(in: statusText.string,
                                         options: [],
                                         range: range).map(\.range)

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

    func processGIFData(data: Data) {
      isMediasLoading = true
      let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).gif")
      try? data.write(to: url)
      let container = MediaContainer(id: UUID().uuidString,
                                     image: nil,
                                     movieTransferable: nil,
                                     gifTransferable: .init(url: url),
                                     mediaAttachment: nil,
                                     error: nil)
      prepareToPost(for: container)
    }

    func processCameraPhoto(image: UIImage) {
      let container = MediaContainer(
        id: UUID().uuidString,
        image: image,
        movieTransferable: nil,
        gifTransferable: nil,
        mediaAttachment: nil,
        error: nil
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
                let container = MediaContainer(
                  id: UUID().uuidString,
                  image: image,
                  movieTransferable: nil,
                  gifTransferable: nil,
                  mediaAttachment: nil,
                  error: nil
                )
                prepareToPost(for: container)
              } else if let content = content as? ImageFileTranseferable,
                        let compressedData = await compressor.compressImageFrom(url: content.url),
                        let image = UIImage(data: compressedData)
              {
                let container = MediaContainer(
                  id: UUID().uuidString,
                  image: image,
                  movieTransferable: nil,
                  gifTransferable: nil,
                  mediaAttachment: nil,
                  error: nil
                )
                prepareToPost(for: container)
              } else if let video = content as? MovieFileTranseferable {
                let container = MediaContainer(
                  id: UUID().uuidString,
                  image: nil,
                  movieTransferable: video,
                  gifTransferable: nil,
                  mediaAttachment: nil,
                  error: nil
                )
                prepareToPost(for: container)
              } else if let gif = content as? GifFileTranseferable {
                let container = MediaContainer(
                  id: UUID().uuidString,
                  image: nil,
                  movieTransferable: nil,
                  gifTransferable: gif,
                  mediaAttachment: nil,
                  error: nil
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
            guard query.utf8.count > 1 else { return }
            query.removeFirst()
            let accounts: [Account] = try await client.get(endpoint: Search.accountsSearch(query: query,
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
      if !tagsSuggestions.isEmpty ||
        !mentionsSuggestions.isEmpty ||
        currentSuggestionRange != nil ||
        showRecentsTagsInline
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
        replaceTextWith(text: "#\(tag) ", inRange: range)
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
        self.isMediasLoading = false
      }
    }

    nonisolated func makeMediaContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer? {
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

    private static func makeGifContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer? {
      guard let gifFile = try? await pickerItem.loadTransferable(type: GifFileTranseferable.self) else { return nil }

      return MediaContainer(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        image: nil,
        movieTransferable: nil,
        gifTransferable: gifFile,
        mediaAttachment: nil,
        error: nil
      )
    }

    private static func makeMovieContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer? {
      guard let movieFile = try? await pickerItem.loadTransferable(type: MovieFileTranseferable.self) else { return nil }

      return MediaContainer(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        image: nil,
        movieTransferable: movieFile,
        gifTransferable: nil,
        mediaAttachment: nil,
        error: nil
      )
    }

    private static func makeImageContainer(from pickerItem: PhotosPickerItem) async -> MediaContainer? {
      guard let imageFile = try? await pickerItem.loadTransferable(type: ImageFileTranseferable.self) else { return nil }

      let compressor = Compressor()

      guard let compressedData = await compressor.compressImageFrom(url: imageFile.url),
            let image = UIImage(data: compressedData)
      else { return nil }

      return MediaContainer(
        id: pickerItem.itemIdentifier ?? UUID().uuidString,
        image: image,
        movieTransferable: nil,
        gifTransferable: nil,
        mediaAttachment: nil,
        error: nil
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
          containers.append(MediaContainer(
            id: UUID().uuidString,
            image: image,
            movieTransferable: nil,
            gifTransferable: nil,
            mediaAttachment: nil,
            error: nil
          ))
        }

        url.stopAccessingSecurityScopedResource()
      }

      return containers
    }

    func upload(container: MediaContainer) async {
      if let index = indexOf(container: container) {
        let originalContainer = mediaContainers[index]
        guard originalContainer.mediaAttachment == nil else { return }
        let newContainer = MediaContainer(
          id: originalContainer.id,
          image: originalContainer.image,
          movieTransferable: originalContainer.movieTransferable,
          gifTransferable: nil,
          mediaAttachment: nil,
          error: nil
        )
        mediaContainers[index] = newContainer
        do {
          let compressor = Compressor()
          if let image = originalContainer.image {
            let imageData = try await compressor.compressImageForUpload(image)
            let uploadedMedia = try await uploadMedia(data: imageData, mimeType: "image/jpeg")
            if let index = indexOf(container: newContainer) {
              mediaContainers[index] = MediaContainer(
                id: originalContainer.id,
                image: mode.isInShareExtension ? originalContainer.image : nil,
                movieTransferable: nil,
                gifTransferable: nil,
                mediaAttachment: uploadedMedia,
                error: nil
              )
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
              mediaContainers[index] = MediaContainer(
                id: originalContainer.id,
                image: mode.isInShareExtension ? originalContainer.image : nil,
                movieTransferable: originalContainer.movieTransferable,
                gifTransferable: nil,
                mediaAttachment: uploadedMedia,
                error: nil
              )
            }
            if let uploadedMedia, uploadedMedia.url == nil {
              scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
            }
          } else if let gifData = originalContainer.gifTransferable?.data {
            let uploadedMedia = try await uploadMedia(data: gifData, mimeType: "image/gif")
            if let index = indexOf(container: newContainer) {
              mediaContainers[index] = MediaContainer(
                id: originalContainer.id,
                image: mode.isInShareExtension ? originalContainer.image : nil,
                movieTransferable: nil,
                gifTransferable: originalContainer.gifTransferable,
                mediaAttachment: uploadedMedia,
                error: nil
              )
            }
            if let uploadedMedia, uploadedMedia.url == nil {
              scheduleAsyncMediaRefresh(mediaAttachement: uploadedMedia)
            }
          }
        } catch {
          if let index = indexOf(container: newContainer) {
            mediaContainers[index] = MediaContainer(
              id: originalContainer.id,
              image: originalContainer.image,
              movieTransferable: nil,
              gifTransferable: nil,
              mediaAttachment: nil,
              error: error
            )
          }
        }
      }
    }

    private func scheduleAsyncMediaRefresh(mediaAttachement: MediaAttachment) {
      Task {
        repeat {
          if let client,
             let index = mediaContainers.firstIndex(where: { $0.mediaAttachment?.id == mediaAttachement.id })
          {
            guard mediaContainers[index].mediaAttachment?.url == nil else {
              return
            }
            do {
              let newAttachement: MediaAttachment = try await client.get(endpoint: Media.media(id: mediaAttachement.id,
                                                                                               json: nil))
              if newAttachement.url != nil {
                let oldContainer = mediaContainers[index]
                mediaContainers[index] = MediaContainer(
                  id: mediaAttachement.id,
                  image: oldContainer.image,
                  movieTransferable: oldContainer.movieTransferable,
                  gifTransferable: oldContainer.gifTransferable,
                  mediaAttachment: newAttachement,
                  error: nil
                )
              }
            } catch {}
          }
          try? await Task.sleep(for: .seconds(5))
        } while !Task.isCancelled
      }
    }

    func addDescription(container: MediaContainer, description: String) async {
      guard let client, let attachment = container.mediaAttachment else { return }
      if let index = indexOf(container: container) {
        do {
          let media: MediaAttachment = try await client.put(endpoint: Media.media(id: attachment.id,
                                                                                  json: .init(description: description)))
          mediaContainers[index] = MediaContainer(
            id: container.id,
            image: nil,
            movieTransferable: nil,
            gifTransferable: nil,
            mediaAttachment: media,
            error: nil
          )
        } catch {}
      }
    }

    private var mediaAttributes: [StatusData.MediaAttribute] = []
    func editDescription(container: MediaContainer, description: String) async {
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
          if rhs.key == "Custom" { false }
          else if lhs.key == "Custom" { true }
          else { lhs.key < rhs.key }
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

extension PhotosPickerItem: @unchecked Sendable {}
