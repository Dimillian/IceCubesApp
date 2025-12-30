import Models
import UIKit
@testable import StatusKit
import XCTest

@MainActor
final class TextEditingServiceTests: XCTestCase {
  func testInsertStatusTextUpdatesString() {
    let service = StatusEditor.TextEditingService()
    let viewModel = StatusEditor.ViewModel(mode: .new(text: nil, visibility: .pub))
    let textView = UITextView()
    textView.text = "Hi"
    textView.selectedRange = NSRange(location: 2, length: 0)
    viewModel.textView = textView
    viewModel.textState.statusText = NSMutableAttributedString(string: "Hi")

    service.insertStatusText("!", in: viewModel)

    XCTAssertEqual(viewModel.textState.statusText.string, "Hi!")
  }

  func testReplaceTextUpdatesString() {
    let service = StatusEditor.TextEditingService()
    let viewModel = StatusEditor.ViewModel(mode: .new(text: nil, visibility: .pub))
    let textView = UITextView()
    textView.selectedRange = NSRange(location: 0, length: 0)
    viewModel.textView = textView
    viewModel.textState.statusText = NSMutableAttributedString(string: "Hello")

    service.replaceText("Hi", in: NSRange(location: 0, length: 5), in: viewModel)

    XCTAssertEqual(viewModel.textState.statusText.string, "Hi")
  }

  func testApplyTextChangesSetsStatusText() {
    let service = StatusEditor.TextEditingService()
    let viewModel = StatusEditor.ViewModel(mode: .new(text: nil, visibility: .pub))
    let changes = StatusEditor.TextService.InitialTextChanges(
      statusText: .init(string: "Draft"),
      selectedRange: NSRange(location: 5, length: 0),
      mentionString: nil,
      spoilerOn: nil,
      spoilerText: nil,
      visibility: nil,
      replyToStatus: nil,
      embeddedStatus: nil
    )

    service.applyTextChanges(changes, in: viewModel)

    XCTAssertEqual(viewModel.textState.statusText.string, "Draft")
  }
}
