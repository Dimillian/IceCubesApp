import Foundation
import Testing

@testable import Models

@Test
func testURLInit() throws {
  let simpleUrl = URL(string: "https://www.google.com", encodePath: true)
  #expect("https://www.google.com" == simpleUrl?.absoluteString)

  let urlWithTrailingSlash = URL(string: "https://www.google.com/", encodePath: true)
  #expect("https://www.google.com/" == urlWithTrailingSlash?.absoluteString)

  let extendedCharPath = URL(
    string: "https://en.wikipedia.org/wiki/Elbbrücken_station", encodePath: true)
  #expect(
    "https://en.wikipedia.org/wiki/Elbbr%C3%BCcken_station" == extendedCharPath?.absoluteString)

  let extendedCharQuery = URL(string: "http://test.com/blah/city?name=京都市", encodePath: true)
  #expect(
    "http://test.com/blah/city?name=%E4%BA%AC%E9%83%BD%E5%B8%82"
      == extendedCharQuery?.absoluteString)

  // Double encoding will happen if you ask to encodePath on an already encoded string
  let alreadyEncodedPath = URL(
    string: "https://en.wikipedia.org/wiki/Elbbr%C3%BCcken_station", encodePath: true)
  #expect(
    "https://en.wikipedia.org/wiki/Elbbr%25C3%25BCcken_station"
      == alreadyEncodedPath?.absoluteString)
}

@Test
func testHTMLStringInit() throws {
  let decoder = JSONDecoder()

  let basicContent = "\"<p>This is a test</p>\""
  var htmlString = try decoder.decode(HTMLString.self, from: Data(basicContent.utf8))
  #expect("This is a test" == htmlString.asRawText)
  #expect("<p>This is a test</p>" == htmlString.htmlValue)
  #expect("This is a test" == htmlString.asMarkdown)
  #expect(0 == htmlString.statusesURLs.count)
  #expect(0 == htmlString.links.count)

  let basicLink = "\"<p>This is a <a href=\\\"https://test.com\\\">test</a></p>\""
  htmlString = try decoder.decode(HTMLString.self, from: Data(basicLink.utf8))
  #expect("This is a test" == htmlString.asRawText)
  #expect("<p>This is a <a href=\"https://test.com\">test</a></p>" == htmlString.htmlValue)
  #expect("This is a [test](https://test.com)" == htmlString.asMarkdown)
  #expect(0 == htmlString.statusesURLs.count)
  #expect(1 == htmlString.links.count)
  #expect("https://test.com" == htmlString.links[0].url.absoluteString)
  #expect("test" == htmlString.links[0].displayString)

  let extendedCharLink = "\"<p>This is a <a href=\\\"https://test.com/goßëña\\\">test</a></p>\""
  htmlString = try decoder.decode(HTMLString.self, from: Data(extendedCharLink.utf8))
  #expect("This is a test" == htmlString.asRawText)
  #expect("<p>This is a <a href=\"https://test.com/goßëña\">test</a></p>" == htmlString.htmlValue)
  #expect("This is a [test](https://test.com/go%C3%9F%C3%AB%C3%B1a)" == htmlString.asMarkdown)
  #expect(0 == htmlString.statusesURLs.count)
  #expect(1 == htmlString.links.count)
  #expect("https://test.com/go%C3%9F%C3%AB%C3%B1a" == htmlString.links[0].url.absoluteString)
  #expect("test" == htmlString.links[0].displayString)

  let alreadyEncodedLink =
    "\"<p>This is a <a href=\\\"https://test.com/go%C3%9F%C3%AB%C3%B1a\\\">test</a></p>\""
  htmlString = try decoder.decode(HTMLString.self, from: Data(alreadyEncodedLink.utf8))
  #expect("This is a test" == htmlString.asRawText)
  #expect(
    "<p>This is a <a href=\"https://test.com/go%C3%9F%C3%AB%C3%B1a\">test</a></p>"
      == htmlString.htmlValue)
  #expect("This is a [test](https://test.com/go%C3%9F%C3%AB%C3%B1a)" == htmlString.asMarkdown)
  #expect(0 == htmlString.statusesURLs.count)
  #expect(1 == htmlString.links.count)
  #expect("https://test.com/go%C3%9F%C3%AB%C3%B1a" == htmlString.links[0].url.absoluteString)
  #expect("test" == htmlString.links[0].displayString)
}

@Test
func testHTMLStringInit_markdownEscaping() throws {
  let decoder = JSONDecoder()

  let stdMarkdownContent = "\"<p>This [*is*] `a`\\n**test**</p>\""
  var htmlString = try decoder.decode(HTMLString.self, from: Data(stdMarkdownContent.utf8))
  #expect("This [*is*] `a`\n**test**" == htmlString.asRawText)
  #expect("<p>This [*is*] `a`\n**test**</p>" == htmlString.htmlValue)
  #expect("This \\[\\*is\\*] \\`a\\` \\*\\*test\\*\\*" == htmlString.asMarkdown)

  let underscoreContent = "\"<p>This _is_ an :emoji_maybe:</p>\""
  htmlString = try decoder.decode(HTMLString.self, from: Data(underscoreContent.utf8))
  #expect("This _is_ an :emoji_maybe:" == htmlString.asRawText)
  #expect("<p>This _is_ an :emoji_maybe:</p>" == htmlString.htmlValue)
  #expect("This \\_is\\_ an :emoji_maybe:" == htmlString.asMarkdown)

  let strikeContent = "\"<p>This ~is~ a\\n`test`</p>\""
  htmlString = try decoder.decode(HTMLString.self, from: Data(strikeContent.utf8))
  #expect("This ~is~ a\n`test`" == htmlString.asRawText)
  #expect("<p>This ~is~ a\n`test`</p>" == htmlString.htmlValue)
  #expect("This \\~is\\~ a \\`test\\`" == htmlString.asMarkdown)
}
