import AVFoundation
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

extension StatusEditor {
  @MainActor
  @Observable public class EditorStore: NSObject, Identifiable {
    public let id = UUID()

    var mode: Mode

    typealias EditorClient = AutocompleteService.Client
      & MediaUploadService.Client
      & MediaDescriptionService.Client
      & PostingService.Client
      & CustomEmojiService.Client
    var client: (any EditorClient)?
    var currentAccount: Account? {
      didSet {
        if itemsProvider != nil {
          mediaContainers = []
        }
      }
    }

    var theme: Theme?
    var preferences: UserPreferences?
    var currentInstance: CurrentInstance?
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

    var textState = TextState()
    private let textEditingService = TextEditingService()
    private let autocompleteService = AutocompleteService()
    private let mediaIngestionService = MediaIngestionService()
    private let mediaUploadService = MediaUploadService()
    private let mediaDescriptionService = MediaDescriptionService()
    private let postingService = PostingService()
    private let customEmojiService = CustomEmojiService()
    private var suggestedTask: Task<Void, Never>?
    private var hasConfigured = false
    private var mediaUploadPolicy: MediaUploadService.UploadPolicy {
      MediaUploadService.UploadPolicy(
        maxConcurrentUploads: 2,
        retryCount: 2,
        retryBackoffBase: .seconds(1),
        retryBackoffMultiplier: 2,
        maxBytes: nil,
        requiresAltText: false
      )
    }

    private var spoilerTextCount: Int {
      spoilerOn ? spoilerText.utf16.count : 0
    }

    var statusTextCharacterLength: Int {
      textState.urlLengthAdjustments - textState.statusText.string.utf16.count - spoilerTextCount
    }

    private var itemsProvider: [NSItemProvider]?

    var statusText: NSMutableAttributedString {
      textState.statusText
    }

    var backupStatusText: NSAttributedString? {
      get { textState.backupStatusText }
      set { textState.backupStatusText = newValue }
    }

    var statusTextBinding: Binding<NSMutableAttributedString> {
      Binding(
        get: { self.textState.statusText },
        set: { newValue in
          self.textEditingService.updateStatusText(newValue, in: self)
        }
      )
    }

    var showPoll: Bool = false
    var pollVotingFrequency = PollVotingFrequency.oneVote
    var pollDuration = Duration.oneDay
    var pollOptions: [String] = ["", ""]

    var spoilerOn: Bool = false
    var spoilerText: String = ""

    var postingProgress: Double = 0.0
    var postingTimer: Timer?
    var isPosting: Bool = false
    var postingToastID: UUID?

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
      textState.statusText.length > 0 || !mediaContainers.isEmpty
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
      var modifiedStatusText = textState.statusText.string.trimmingCharacters(in: .whitespaces)

      if let mentionString = textState.mentionString, modifiedStatusText.hasPrefix(mentionString) {
        modifiedStatusText = String(modifiedStatusText.dropFirst(mentionString.count))
      }

      return !modifiedStatusText.isEmpty && !mode.isInShareExtension
    }

    // Map of container.id -> initial alt text (from intents)
    private var pendingMediaDescriptions = MediaDescriptionService.PendingStore()

    var visibility: Models.Visibility = .pub

    var mentionsSuggestions: [Account] = []
    var tagsSuggestions: [Tag] = []
    var showRecentsTagsInline: Bool = false
    var selectedLanguage: String?
    var hasExplicitlySelectedLanguage: Bool = false
    var embeddedStatusURL: URL? {
      URL(string: embeddedStatus?.reblog?.url ?? embeddedStatus?.url ?? "")
    }

    init(mode: Mode) {
      self.mode = mode

      #if !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *), Assistant.isAvailable {
          Assistant.prewarm()
        }
      #endif
    }

    func configureIfNeeded(
      client: any EditorClient,
      currentAccount: Account?,
      theme: Theme,
      preferences: UserPreferences,
      currentInstance: CurrentInstance
    ) {
      guard !hasConfigured else { return }

      self.client = client
      self.currentAccount = currentAccount
      self.theme = theme
      self.preferences = preferences
      self.currentInstance = currentInstance
      prepareStatusText()
      Task { await fetchCustomEmojis() }

      hasConfigured = true
    }

    func makeFollowUpStore() -> EditorStore {
      let store = EditorStore(mode: .new(text: nil, visibility: visibility))

      if let client,
        let theme,
        let preferences,
        let currentInstance
      {
        store.configureIfNeeded(
          client: client,
          currentAccount: currentAccount,
          theme: theme,
          preferences: preferences,
          currentInstance: currentInstance
        )
      }

      return store
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
      if let detectedLang = detectLanguage(text: textState.statusText.string),
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
        postingProgress = 0
        if let postingToastID {
          ToastCenter.shared.updateProgress(id: postingToastID, progress: postingProgress)
        }
        if postingTimer == nil {
          Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
              if self.postingProgress < 100 {
                self.postingProgress += 0.5
                if let postingToastID = self.postingToastID {
                  ToastCenter.shared.updateProgress(id: postingToastID, progress: self.postingProgress)
                }
              }
              if self.postingProgress >= 100 {
                self.postingTimer?.invalidate()
                self.postingTimer = nil
              }
            }
          }
        }

        isPosting = true
        // Fallback: include any pending alt text in mediaAttributes if media got uploaded
        if !pendingMediaDescriptions.altTextByContainerId.isEmpty {
          mediaDescriptionService.applyPendingAltText(
            mediaContainers: mediaContainers,
            store: &pendingMediaDescriptions
          )
        }

        let input = PostingService.Input(
          mode: mode,
          statusText: textState.statusText.string,
          visibility: visibility,
          spoilerOn: spoilerOn,
          spoilerText: spoilerText,
          mediaAttachments: mediaContainers.compactMap { $0.mediaAttachment },
          pollOptions: getPollOptionsForAPI(),
          pollVotingFrequency: pollVotingFrequency,
          pollDuration: pollDuration,
          selectedLanguage: selectedLanguage,
          pendingMediaAttributes: pendingMediaDescriptions.mediaAttributes,
          embeddedStatusId: embeddedStatus?.id,
          allMediaHasDescription: allMediaHasDescription,
          requiresAltText: preferences?.appRequireAltText ?? UserPreferences.shared.appRequireAltText
        )

        let postStatus = try await postingService.submit(
          input: input,
          client: client
        )

        postingTimer?.invalidate()
        postingTimer = nil

        withAnimation {
          postingProgress = 100.0
        }
        if let postingToastID {
          ToastCenter.shared.updateProgress(id: postingToastID, progress: postingProgress)
        }
        try await Task.sleep(for: .seconds(0.5))
        HapticManager.shared.fireHaptic(.notification(.success))

        if hasExplicitlySelectedLanguage, let selectedLanguage {
          preferences?.markLanguageAsSelected(isoCode: selectedLanguage)
        }
        isPosting = false

        return postStatus
      } catch {
        postingTimer?.invalidate()
        postingTimer = nil
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
      textEditingService.insertStatusText(text, in: self)
    }

    func replaceTextWith(text: String, inRange: NSRange) {
      textEditingService.replaceText(text, in: inRange, in: self)
    }

    func replaceTextWith(text: String) {
      textEditingService.replaceText(text, in: self)
    }

    func prepareStatusText() {
      let textChanges = textEditingService.initialTextChanges(
        for: mode,
        currentAccount: currentAccount,
        currentInstance: currentInstance,
        preferences: preferences
      )
      textEditingService.applyTextChanges(textChanges, in: self)

      switch mode {
      case .shareExtension(let items):
        itemsProvider = items
        processItemsProvider(items: items)
      case .imageURL(let urls, _, let altTexts, _):
        Task {
          let containers = await Self.makeImageContainer(from: urls)
          if let altTexts {
            for (i, c) in containers.enumerated() where i < altTexts.count {
              let desc = altTexts[i].trimmingCharacters(in: .whitespacesAndNewlines)
              if !desc.isEmpty {
                pendingMediaDescriptions.altTextByContainerId[c.id] = desc
              }
            }
          }
          prepareToPost(for: containers)
        }
      case .edit(let status):
        mediaContainers = status.mediaAttachments.map {
          MediaContainer.uploaded(
            id: UUID().uuidString,
            attachment: $0,
            originalImage: nil
          )
        }
      default:
        break
      }
    }

    // Text processing handled by TextEditingService.

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
        let result = await mediaIngestionService.ingest(
          items: items,
          makeVideoPreview: Self.extractVideoPreview(from:)
        )
        if result.hadError {
          isMediasLoading = false
        }
        prepareToPost(for: result.containers)
        if !result.initialText.isEmpty {
          textEditingService.updateStatusText(
            .init(string: "\n\n\(result.initialText)"),
            selection: .init(location: 0, length: 0),
            in: self
          )
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

    // MARK: - Autocomplete

    func loadAutoCompleteResults(query: String) {
      guard let client else { return }
      suggestedTask?.cancel()
      suggestedTask = Task {
        do {
          let result = try await autocompleteService.fetchSuggestions(for: query, client: client)
          guard !Task.isCancelled else {
            return
          }
          switch result {
          case .showRecentsTagsInline:
            withAnimation {
              showRecentsTagsInline = true
            }
          case .tags(let tags):
            withAnimation {
              showRecentsTagsInline = false
              tagsSuggestions = tags
            }
          case .mentions(let accounts):
            withAnimation {
              mentionsSuggestions = accounts
            }
          case .none:
            break
          }
        } catch {}
      }
    }

    func resetAutoCompletion() {
      if !tagsSuggestions.isEmpty || !mentionsSuggestions.isEmpty
        || textState.currentSuggestionRange != nil
        || showRecentsTagsInline
      {
        withAnimation {
          tagsSuggestions = []
          mentionsSuggestions = []
          textState.currentSuggestionRange = nil
          showRecentsTagsInline = false
        }
      }
    }

    func selectMentionSuggestion(account: Account) {
      if let range = textState.currentSuggestionRange {
        replaceTextWith(text: "@\(account.acct) ", inRange: range)
      }
    }

    func selectHashtagSuggestion(tag: String) {
      if let range = textState.currentSuggestionRange {
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
          newStream = await assistant.correct(message: textState.statusText.string)
        case .emphasize:
          newStream = await assistant.emphasize(message: textState.statusText.string)
        case .fit:
          newStream = await assistant.shorten(message: textState.statusText.string)
        case .rewriteWithTone(let tone):
          newStream = await assistant.adjustTone(message: textState.statusText.string, to: tone)
        }

        if let newStream {
          textState.backupStatusText = textState.statusText
          do {
            for try await content in newStream {
              replaceTextWith(text: content.content)
            }
          } catch {
            if let backupStatusText = textState.backupStatusText {
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
        await upload(containers: [container])
        self.isMediasLoading = false
      }
    }

    func prepareToPost(for containers: [MediaContainer]) {
      Task(priority: .high) {
        guard !containers.isEmpty else { return }
        self.mediaContainers.append(contentsOf: containers)
        await upload(containers: containers)
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
      let previewImage: UIImage? = nil  // GIFs typically show animated preview

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

      guard let client else { return }
      let input = MediaUploadService.UploadInput(
        id: originalContainer.id,
        content: content,
        altText: pendingMediaDescriptions.altTextByContainerId[originalContainer.id]
      )
      let result = await mediaUploadService.upload(
        input: input,
        client: client,
        modeIsShareExtension: mode.isInShareExtension,
        policy: mediaUploadPolicy
      ) { [weak self] progress in
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

      await handleUploadResult(result, for: originalContainer, content: content)
    }

    private func upload(containers: [MediaContainer]) async {
      guard let client else { return }
      let inputs = containers.compactMap { container -> MediaUploadService.UploadInput? in
        guard case .pending(let content) = container.state else { return nil }
        return MediaUploadService.UploadInput(
          id: container.id,
          content: content,
          altText: pendingMediaDescriptions.altTextByContainerId[container.id]
        )
      }

      await mediaUploadService.uploadBatch(
        inputs: inputs,
        client: client,
        modeIsShareExtension: mode.isInShareExtension,
        policy: mediaUploadPolicy
      ) { [weak self] event in
        guard let self else { return }
        switch event {
        case .started(let id, let content):
          if let index = self.mediaContainers.firstIndex(where: { $0.id == id }) {
            self.mediaContainers[index] = MediaContainer(
              id: id,
              state: .uploading(content: content, progress: 0.0)
            )
          }
        case .progress(let id, let content, let progress):
          if let index = self.mediaContainers.firstIndex(where: { $0.id == id }) {
            self.mediaContainers[index] = MediaContainer(
              id: id,
              state: .uploading(content: content, progress: progress)
            )
          }
        case .success(let id, let result):
          if let index = self.mediaContainers.firstIndex(where: { $0.id == id }) {
            self.mediaContainers[index] = MediaContainer.uploaded(
              id: id,
              attachment: result.attachment,
              originalImage: result.originalImage
            )
          }
          if result.needsRefresh {
            mediaUploadService.scheduleAsyncMediaRefresh(
              attachment: result.attachment,
              client: client
            ) { [weak self] refreshed in
              guard let self else { return }
              if let index = self.mediaContainers.firstIndex(where: {
                $0.mediaAttachment?.id == refreshed.id
              }) {
                if case .uploaded(_, let originalImage) = self.mediaContainers[index].state {
                  self.mediaContainers[index] = MediaContainer.uploaded(
                    id: self.mediaContainers[index].id,
                    attachment: refreshed,
                    originalImage: originalImage
                  )
                }
              }
            }
          }
          if let desc = pendingMediaDescriptions.altTextByContainerId[id], !desc.isEmpty {
            Task { @MainActor in
              guard let client = self.client,
                let container = self.mediaContainers.first(where: { $0.id == id })
              else { return }
              if let updated = await self.mediaDescriptionService.addDescription(
                container: container,
                description: desc,
                client: client
              ) {
                if let index = self.indexOf(container: container) {
                  if case .uploaded(_, let originalImage) = self.mediaContainers[index].state {
                    self.mediaContainers[index] = MediaContainer.uploaded(
                      id: self.mediaContainers[index].id,
                      attachment: updated,
                      originalImage: originalImage
                    )
                  }
                }
              }
              self.pendingMediaDescriptions.altTextByContainerId.removeValue(forKey: id)
            }
          }
        case .failure(let id, let content, let error):
          if let index = self.mediaContainers.firstIndex(where: { $0.id == id }) {
            self.mediaContainers[index] = MediaContainer.failed(
              id: id,
              content: content,
              error: error
            )
          }
        }
      }
    }

    private func handleUploadResult(
      _ result: Result<MediaUploadService.UploadResult, MediaContainer.MediaError>,
      for container: MediaContainer,
      content: MediaContainer.MediaContent
    ) async {
      guard let index = indexOf(container: container) else { return }
      switch result {
      case .success(let result):
        mediaContainers[index] = MediaContainer.uploaded(
          id: container.id,
          attachment: result.attachment,
          originalImage: result.originalImage
        )
        if result.needsRefresh, let client {
          mediaUploadService.scheduleAsyncMediaRefresh(
            attachment: result.attachment,
            client: client
          ) { [weak self] refreshed in
            guard let self else { return }
            if let index = self.mediaContainers.firstIndex(where: {
              $0.mediaAttachment?.id == refreshed.id
            }) {
              if case .uploaded(_, let originalImage) = self.mediaContainers[index].state {
                self.mediaContainers[index] = MediaContainer.uploaded(
                  id: self.mediaContainers[index].id,
                  attachment: refreshed,
                  originalImage: originalImage
                )
              }
            }
          }
        }
        if let desc = pendingMediaDescriptions.altTextByContainerId[container.id], !desc.isEmpty,
          let client
        {
          if let updated = await mediaDescriptionService.addDescription(
            container: mediaContainers[index],
            description: desc,
            client: client
          ) {
            if case .uploaded(_, let originalImage) = mediaContainers[index].state {
              mediaContainers[index] = MediaContainer.uploaded(
                id: mediaContainers[index].id,
                attachment: updated,
                originalImage: originalImage
              )
            }
          }
          pendingMediaDescriptions.altTextByContainerId.removeValue(forKey: container.id)
        }
      case .failure(let error):
        mediaContainers[index] = MediaContainer.failed(
          id: container.id,
          content: content,
          error: error
        )
      }
    }

    func addDescription(container: MediaContainer, description: String) async {
      guard let client,
        let index = indexOf(container: container)
      else { return }
      if let updated = await mediaDescriptionService.addDescription(
        container: mediaContainers[index],
        description: description,
        client: client
      ) {
        if case .uploaded(_, let originalImage) = mediaContainers[index].state {
          mediaContainers[index] = MediaContainer.uploaded(
            id: mediaContainers[index].id,
            attachment: updated,
            originalImage: originalImage
          )
        }
      }
    }

    func editDescription(container: MediaContainer, description: String) async {
      guard let attachment = container.mediaAttachment else { return }
      if indexOf(container: container) != nil {
        mediaDescriptionService.buildMediaAttribute(
          attachment: attachment,
          description: description,
          store: &pendingMediaDescriptions
        )
      }
    }

    // Media upload handled by MediaUploadService.

    // MARK: - Custom emojis

    func fetchCustomEmojis() async {
      guard let client else { return }
      do {
        customEmojiContainer = try await customEmojiService.fetchContainers(client: client)
      } catch {}
    }
  }
}

// MARK: - DropDelegate

extension StatusEditor.EditorStore: DropDelegate {
  public func performDrop(info: DropInfo) -> Bool {
    let item = info.itemProviders(for: [.image, .video, .gif, .mpeg4Movie, .quickTimeMovie, .movie])
    processItemsProvider(items: item)
    return true
  }
}

// MARK: - UITextPasteDelegate

extension StatusEditor.EditorStore: UITextPasteDelegate {
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
