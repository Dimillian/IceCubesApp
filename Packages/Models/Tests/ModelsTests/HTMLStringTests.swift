@testable import Models
import XCTest

final class HTMLStringTests: XCTestCase {
  func testURLInit() throws {
    XCTAssertNil(URL(string: "", encodePath: true))

    let simpleUrl = URL(string: "https://www.google.com", encodePath: true)
    XCTAssertEqual("https://www.google.com", simpleUrl?.absoluteString)

    let urlWithTrailingSlash = URL(string: "https://www.google.com/", encodePath: true)
    XCTAssertEqual("https://www.google.com/", urlWithTrailingSlash?.absoluteString)

    let extendedCharPath = URL(string: "https://en.wikipedia.org/wiki/Elbbrücken_station", encodePath: true)
    XCTAssertEqual("https://en.wikipedia.org/wiki/Elbbr%C3%BCcken_station", extendedCharPath?.absoluteString)

    let extendedCharQuery = URL(string: "http://test.com/blah/city?name=京都市", encodePath: true)
    XCTAssertEqual("http://test.com/blah/city?name=%E4%BA%AC%E9%83%BD%E5%B8%82", extendedCharQuery?.absoluteString)

    // Double encoding will happen if you ask to encodePath on an already encoded string
    let alreadyEncodedPath = URL(string: "https://en.wikipedia.org/wiki/Elbbr%C3%BCcken_station", encodePath: true)
    XCTAssertEqual("https://en.wikipedia.org/wiki/Elbbr%25C3%25BCcken_station", alreadyEncodedPath?.absoluteString)
  }

  func testHTMLStringInit() throws {
    let decoder = JSONDecoder()

    let basicContent = "\"<p>This is a test</p>\""
    var htmlString = try decoder.decode(HTMLString.self, from: Data(basicContent.utf8))
    XCTAssertEqual("This is a test", htmlString.asRawText)
    XCTAssertEqual("<p>This is a test</p>", htmlString.htmlValue)
    XCTAssertEqual("This is a test", htmlString.asMarkdown)
    XCTAssertEqual(0, htmlString.statusesURLs.count)
    XCTAssertEqual(0, htmlString.links.count)

    let basicLink = "\"<p>This is a <a href=\\\"https://test.com\\\">test</a></p>\""
    htmlString = try decoder.decode(HTMLString.self, from: Data(basicLink.utf8))
    XCTAssertEqual("This is a test", htmlString.asRawText)
    XCTAssertEqual("<p>This is a <a href=\"https://test.com\">test</a></p>", htmlString.htmlValue)
    XCTAssertEqual("This is a [test](https://test.com)", htmlString.asMarkdown)
    XCTAssertEqual(0, htmlString.statusesURLs.count)
    XCTAssertEqual(1, htmlString.links.count)
    XCTAssertEqual("https://test.com", htmlString.links[0].url.absoluteString)
    XCTAssertEqual("test", htmlString.links[0].displayString)

    let extendedCharLink = "\"<p>This is a <a href=\\\"https://test.com/goßëña\\\">test</a></p>\""
    htmlString = try decoder.decode(HTMLString.self, from: Data(extendedCharLink.utf8))
    XCTAssertEqual("This is a test", htmlString.asRawText)
    XCTAssertEqual("<p>This is a <a href=\"https://test.com/goßëña\">test</a></p>", htmlString.htmlValue)
    XCTAssertEqual("This is a [test](https://test.com/go%C3%9F%C3%AB%C3%B1a)", htmlString.asMarkdown)
    XCTAssertEqual(0, htmlString.statusesURLs.count)
    XCTAssertEqual(1, htmlString.links.count)
    XCTAssertEqual("https://test.com/go%C3%9F%C3%AB%C3%B1a", htmlString.links[0].url.absoluteString)
    XCTAssertEqual("test", htmlString.links[0].displayString)

    let alreadyEncodedLink = "\"<p>This is a <a href=\\\"https://test.com/go%C3%9F%C3%AB%C3%B1a\\\">test</a></p>\""
    htmlString = try decoder.decode(HTMLString.self, from: Data(alreadyEncodedLink.utf8))
    XCTAssertEqual("This is a test", htmlString.asRawText)
    XCTAssertEqual("<p>This is a <a href=\"https://test.com/go%C3%9F%C3%AB%C3%B1a\">test</a></p>", htmlString.htmlValue)
    XCTAssertEqual("This is a [test](https://test.com/go%C3%9F%C3%AB%C3%B1a)", htmlString.asMarkdown)
    XCTAssertEqual(0, htmlString.statusesURLs.count)
    XCTAssertEqual(1, htmlString.links.count)
    XCTAssertEqual("https://test.com/go%C3%9F%C3%AB%C3%B1a", htmlString.links[0].url.absoluteString)
    XCTAssertEqual("test", htmlString.links[0].displayString)
  }

  func testHTMLStringInit_markdownEscaping() throws {
    let decoder = JSONDecoder()

    let stdMarkdownContent = "\"<p>This [*is*] `a`\\n**test**</p>\""
    var htmlString = try decoder.decode(HTMLString.self, from: Data(stdMarkdownContent.utf8))
    XCTAssertEqual("This [*is*] `a`\n**test**", htmlString.asRawText)
    XCTAssertEqual("<p>This [*is*] `a`\n**test**</p>", htmlString.htmlValue)
    XCTAssertEqual("This \\[\\*is\\*] \\`a\\` \\*\\*test\\*\\*", htmlString.asMarkdown)

    let underscoreContent = "\"<p>This _is_ an :emoji_maybe:</p>\""
    htmlString = try decoder.decode(HTMLString.self, from: Data(underscoreContent.utf8))
    XCTAssertEqual("This _is_ an :emoji_maybe:", htmlString.asRawText)
    XCTAssertEqual("<p>This _is_ an :emoji_maybe:</p>", htmlString.htmlValue)
    XCTAssertEqual("This \\_is\\_ an :emoji_maybe:", htmlString.asMarkdown)

    let strikeContent = "\"<p>This ~is~ a\\n`test`</p>\""
    htmlString = try decoder.decode(HTMLString.self, from: Data(strikeContent.utf8))
    XCTAssertEqual("This ~is~ a\n`test`", htmlString.asRawText)
    XCTAssertEqual("<p>This ~is~ a\n`test`</p>", htmlString.htmlValue)
    XCTAssertEqual("This \\~is\\~ a \\`test\\`", htmlString.asMarkdown)
  }
}
