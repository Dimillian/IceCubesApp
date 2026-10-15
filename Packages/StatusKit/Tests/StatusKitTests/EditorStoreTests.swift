import DesignSystem
import Env
import Models
import NetworkClient
@testable import StatusKit
import XCTest

@MainActor
final class EditorStoreTests: XCTestCase {
  func testConfigureIfNeededSetsInitialTextAndVisibility() {
    let store = StatusEditor.EditorStore(mode: .new(text: "Hello", visibility: .priv))
    let client = MockEditorClient()

    store.configureIfNeeded(
      client: client,
      currentAccount: nil,
      theme: Theme.shared,
      preferences: UserPreferences.shared,
      currentInstance: CurrentInstance.shared
    )

    XCTAssertEqual(store.statusText.string, "Hello")
    XCTAssertEqual(store.visibility, .priv)
  }

  func testConfigureIfNeededRunsOnce() {
    let store = StatusEditor.EditorStore(mode: .new(text: "Hello", visibility: .pub))
    let client = MockEditorClient()

    store.configureIfNeeded(
      client: client,
      currentAccount: nil,
      theme: Theme.shared,
      preferences: UserPreferences.shared,
      currentInstance: CurrentInstance.shared
    )

    store.textState.statusText = NSMutableAttributedString(string: "Changed")

    store.configureIfNeeded(
      client: client,
      currentAccount: nil,
      theme: Theme.shared,
      preferences: UserPreferences.shared,
      currentInstance: CurrentInstance.shared
    )

    XCTAssertEqual(store.statusText.string, "Changed")
  }

  func testPostStatusInvalidatesProgressTimerAfterSuccess() async throws {
    let store = StatusEditor.EditorStore(mode: .new(text: "Hello", visibility: .pub))
    let client = MockEditorClient()
    store.client = client
    var timer: Timer?
    client.onPost = { [weak store] in
      timer = store?.postingTimer
      XCTAssertEqual(timer?.isValid, true)
      return .placeholder()
    }
    let latestEvent = StreamWatcher.shared.latestEvent
    defer {
      timer?.invalidate()
      StreamWatcher.shared.latestEvent = latestEvent
    }

    let status = await store.postStatus()

    XCTAssertNotNil(status)
    XCTAssertFalse(try XCTUnwrap(timer).isValid)
    XCTAssertNil(store.postingTimer)
  }

  func testPostStatusInvalidatesProgressTimerAfterFailure() async throws {
    let store = StatusEditor.EditorStore(mode: .new(text: "Hello", visibility: .pub))
    let client = MockEditorClient()
    store.client = client
    var timer: Timer?
    client.onPost = { [weak store] in
      timer = store?.postingTimer
      XCTAssertEqual(timer?.isValid, true)
      throw MockEditorClient.DummyError()
    }
    defer { timer?.invalidate() }

    let status = await store.postStatus()

    XCTAssertNil(status)
    XCTAssertFalse(try XCTUnwrap(timer).isValid)
    XCTAssertNil(store.postingTimer)
  }

  func testMakeFollowUpStoreCopiesDependencies() {
    let store = StatusEditor.EditorStore(mode: .new(text: nil, visibility: .priv))
    let client = MockEditorClient()

    store.configureIfNeeded(
      client: client,
      currentAccount: nil,
      theme: Theme.shared,
      preferences: UserPreferences.shared,
      currentInstance: CurrentInstance.shared
    )

    let followUp = store.makeFollowUpStore()

    XCTAssertEqual(followUp.visibility, .priv)
    XCTAssertNotNil(followUp.client)
    XCTAssertNotNil(followUp.theme)
    XCTAssertNotNil(followUp.preferences)
    XCTAssertNotNil(followUp.currentInstance)
  }
}

@MainActor
private final class MockEditorClient: StatusEditor.AutocompleteService.Client,
  StatusEditor.MediaUploadService.Client,
  StatusEditor.MediaDescriptionService.Client,
  StatusEditor.PostingService.Client,
  StatusEditor.CustomEmojiService.Client
{
  struct DummyError: Error {}

  var onPost: (() throws -> Status)?

  func searchHashtags(query: String) async throws -> [Tag] { [] }

  func searchAccounts(query: String) async throws -> [Account] { [] }

  func uploadMedia(
    data: Data,
    mimeType: String,
    progressHandler: @escaping @Sendable (Double) -> Void
  ) async throws -> MediaAttachment? {
    nil
  }

  func fetchMedia(id: String) async throws -> MediaAttachment {
    throw DummyError()
  }

  func updateDescription(mediaId: String, description: String) async throws -> MediaAttachment {
    throw DummyError()
  }

  func postStatus(data: StatusData) async throws -> Status {
    if let onPost {
      return try onPost()
    }
    throw DummyError()
  }

  func editStatus(id: String, data: StatusData) async throws -> Status {
    throw DummyError()
  }

  func fetchCustomEmojis() async throws -> [Emoji] { [] }
}
