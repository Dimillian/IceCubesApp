import Foundation
import XCTest

@testable import NetworkClient

final class OpenAIClientTests: XCTestCase {
  func testImageDescriptionAsksForThePostLanguage() {
    let text = OpenAIClient.Prompt.imageDescriptionText(languageCode: "pl")

    XCTAssertTrue(text.hasSuffix(" Write the description in Polish."))
  }

  func testImageDescriptionWithoutLanguageKeepsTheDefaultPrompt() {
    let text = OpenAIClient.Prompt.imageDescriptionText(languageCode: nil)

    XCTAssertFalse(text.contains("Write the description in"))
  }
}
