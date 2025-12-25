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

@Test
func testHTMLStringInit_lineStartListMarkers() throws {
  let decoder = JSONDecoder()

  let listLikeContent = "\"<p>2025 year review:<br />- 11 accepted and merged pull requests</p>\""
  let htmlString = try decoder.decode(HTMLString.self, from: Data(listLikeContent.utf8))
  #expect("2025 year review:\n- 11 accepted and merged pull requests" == htmlString.asRawText)
  #expect(
    "2025 year review:\n\\- 11 accepted and merged pull requests" == htmlString.asMarkdown)
}

@Test
func testHTMLStringInit_quoteInlineRemoval() throws {
  let decoder = JSONDecoder()
  
  // Test that quote-inline paragraphs are removed
  let quoteContent = "\"<p>Normal text</p><p class=\\\"quote-inline\\\">RE: <a href=\\\"https://example.com\\\">quoted post</a></p><p>More text</p>\""
  let htmlString = try decoder.decode(HTMLString.self, from: Data(quoteContent.utf8))
  #expect("Normal text\n\nMore text" == htmlString.asRawText)
  #expect("<p>Normal text</p><p class=\"quote-inline\">RE: <a href=\"https://example.com\">quoted post</a></p><p>More text</p>" == htmlString.htmlValue)
  #expect("Normal text\n\nMore text" == htmlString.asMarkdown)
  #expect(0 == htmlString.links.count) // The link in quote-inline should not be counted
}

@Test
func testHTMLStringInit_trailingHashtags() throws {
  let decoder = JSONDecoder()
  
  // Test that trailing hashtags are detected and removed
  let hashtagContent = "\"<p>This is a test post</p><p><a href=\\\"https://mastodon.social/tags/swift\\\" class=\\\"mention hashtag\\\" rel=\\\"tag\\\">#<span>swift</span></a> <a href=\\\"https://mastodon.social/tags/ios\\\" class=\\\"mention hashtag\\\" rel=\\\"tag\\\">#<span>ios</span></a></p>\""
  let htmlString = try decoder.decode(HTMLString.self, from: Data(hashtagContent.utf8))
  #expect("This is a test post" == htmlString.asRawText)
  #expect(true == htmlString.hadTrailingTags)
  #expect("This is a test post" == htmlString.asMarkdown)
  #expect(2 == htmlString.links.count) // Links are still tracked even though hashtags are removed
  
  // Test that inline hashtags are NOT removed
  let inlineHashtagContent = "\"<p>This is a <a href=\\\"https://mastodon.social/tags/swift\\\" class=\\\"mention hashtag\\\" rel=\\\"tag\\\">#<span>swift</span></a> test post</p>\""
  let htmlString2 = try decoder.decode(HTMLString.self, from: Data(inlineHashtagContent.utf8))
  #expect("This is a #swift test post" == htmlString2.asRawText)
  #expect(false == htmlString2.hadTrailingTags)
  #expect("This is a [#swift](https://mastodon.social/tags/swift) test post" == htmlString2.asMarkdown)
  #expect(1 == htmlString2.links.count)
  
  // Test multiple hashtags at the end (like the real example from Mastodon)
  let multipleHashtagsContent = "\"<p>An illustration by Pulitzer-winning political cartoonist Ann Telnaes.</p><p>PS: Fuck Washington Post for forcing her out to appease Trump.</p><p><a href=\\\"https://sfba.social/tags/cartoon\\\" class=\\\"mention hashtag\\\" rel=\\\"nofollow noopener\\\" target=\\\"_blank\\\">#<span>cartoon</span></a> <a href=\\\"https://sfba.social/tags/politicalCartoon\\\" class=\\\"mention hashtag\\\" rel=\\\"nofollow noopener\\\" target=\\\"_blank\\\">#<span>politicalCartoon</span></a> <a href=\\\"https://sfba.social/tags/kakistocracy\\\" class=\\\"mention hashtag\\\" rel=\\\"nofollow noopener\\\" target=\\\"_blank\\\">#<span>kakistocracy</span></a> <a href=\\\"https://sfba.social/tags/Trump\\\" class=\\\"mention hashtag\\\" rel=\\\"nofollow noopener\\\" target=\\\"_blank\\\">#<span>Trump</span></a> <a href=\\\"https://sfba.social/tags/TrumpEpstein\\\" class=\\\"mention hashtag\\\" rel=\\\"nofollow noopener\\\" target=\\\"_blank\\\">#<span>TrumpEpstein</span></a></p>\""
  let htmlString3 = try decoder.decode(HTMLString.self, from: Data(multipleHashtagsContent.utf8))
  #expect("An illustration by Pulitzer-winning political cartoonist Ann Telnaes.\n\nPS: Fuck Washington Post for forcing her out to appease Trump." == htmlString3.asRawText)
  #expect(true == htmlString3.hadTrailingTags)
  #expect("An illustration by Pulitzer-winning political cartoonist Ann Telnaes.\n\nPS: Fuck Washington Post for forcing her out to appease Trump." == htmlString3.asMarkdown)
  #expect(5 == htmlString3.links.count) // All hashtag links should still be tracked
  
  // Test that mixed content in last paragraph is NOT removed
  let mixedContent = "\"<p>This is a test</p><p>Check out <a href=\\\"https://example.com\\\">this link</a> and <a href=\\\"https://mastodon.social/tags/swift\\\" class=\\\"mention hashtag\\\" rel=\\\"tag\\\">#<span>swift</span></a></p>\""
  let htmlString4 = try decoder.decode(HTMLString.self, from: Data(mixedContent.utf8))
  #expect("This is a test\n\nCheck out this link and #swift" == htmlString4.asRawText)
  #expect(false == htmlString4.hadTrailingTags) // Mixed content, so tags are not removed
  #expect("This is a test\n\nCheck out [this link](https://example.com) and [#swift](https://mastodon.social/tags/swift)" == htmlString4.asMarkdown)
  #expect(2 == htmlString4.links.count)
}
