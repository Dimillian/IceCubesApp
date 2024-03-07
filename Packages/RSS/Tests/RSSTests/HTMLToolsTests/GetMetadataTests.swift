//
//  GetMetadataTests.swift
//
//
//  Created by Duong Thai on 02/03/2024.
//

import XCTest
@testable import RSS

final class GetMetadataTests: XCTestCase {
  func test_Get_Metadata() throws {
    let fileName = "wadetregaskis-com--a-brief-introduction-to-type-memory-layout-in-swift.html"
    let sourceURL = URL(string: "https://wadetregaskis.com/a-brief-introduction-to-type-memory-layout-in-swift/")!
    let content = Self.getStringFrom(fileName: fileName)

    XCTAssertNil(RSSTools.getTitleOf(html: content))

    XCTAssertNil(RSSTools.getContentTypeOf(html: content))

    XCTAssertNil(RSSTools.getPreviewImageOf(html: content))

    XCTAssertNil(RSSTools.getURLOf(html: content))

    XCTAssertEqual(
      RSSTools.getFaviconOf(html: content, sourceURL: sourceURL)!,
      URL(string: "https://wadetregaskis.com/wp-content/uploads/2016/03/Stitch-512x512-1-256x256.png")!
    )

    XCTAssertEqual(
      RSSTools.getIconOf(html: content, sourceURL: sourceURL)!,
      URL(string: "https://wadetregaskis.com/wp-content/uploads/2016/03/Stitch-512x512-1-256x256.png")!
    )

    XCTAssertNil(RSSTools.getSiteNameOf(html: content))
  }

  func test_Get_Metadata_1() throws {
    let fileName = "swift-org--blog-summer-of-code-2023-summary.html"
    let sourceURL = URL(string: "https://www.swift.org/blog/summer-of-code-2023-summary/")!
    let content = Self.getStringFrom(fileName: fileName)

    XCTAssertEqual(
      RSSTools.getTitleOf(html: content)!.string,
      NonEmptyString("Swift Summer of Code 2023 Summary")!.string
    )

    XCTAssertEqual(
      RSSTools.getContentTypeOf(html: content)!.string,
      NonEmptyString("article")!.string
    )

    XCTAssertEqual(
      RSSTools.getPreviewImageOf(html: content)!,
      URL(string: "https://swift.org/apple-touch-icon-180x180.png")!
    )

    XCTAssertEqual(
      RSSTools.getURLOf(html: content)!,
      URL(string: "https://swift.org/blog/summer-of-code-2023-summary/")!
    )

    XCTAssertEqual(
      RSSTools.getFaviconOf(html: content, sourceURL: sourceURL)!,
      URL(string: "https://www.swift.org/favicon.ico")!
    )

    XCTAssertNil(RSSTools.getIconOf(html: content, sourceURL: sourceURL))

    XCTAssertEqual(
      RSSTools.getSiteNameOf(html: content)!.string,
      NonEmptyString("Swift.org")!.string
    )
  }

  func test_Get_Metadata_2() throws {
    let fileName = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let sourceURL = URL(string: "https://iso.500px.com/10-chilly-new-photos-from-500px-licensing/")!
    let content = Self.getStringFrom(fileName: fileName)

    XCTAssertEqual(
      RSSTools.getTitleOf(html: content)!.string,
      NonEmptyString("10 chilly new photos from 500px Licensing Contributors")!.string
    )

    XCTAssertEqual(
      RSSTools.getContentTypeOf(html: content)!.string,
      NonEmptyString("article")!.string
    )

    XCTAssertEqual(
      RSSTools.getPreviewImageOf(html: content)!,
      URL(string: "https://iso.500px.com/wp-content/uploads/2024/01/Intense-pt.-2-By-Jagoda-Matejczuk-2-1500x1000.jpeg")!
    )

    XCTAssertEqual(
      RSSTools.getURLOf(html: content)!,
      URL(string: "https://iso.500px.com/10-chilly-new-photos-from-500px-licensing/")!
    )

    XCTAssertEqual(
      RSSTools.getFaviconOf(html: content, sourceURL: sourceURL)!,
      URL(string: "https://iso.500px.com/wp-content/themes/photoform/favicon.ico")!
    )

    XCTAssertEqual(
      RSSTools.getIconOf(html: content, sourceURL: sourceURL)!,
      URL(string: "https://iso.500px.com/wp-content/uploads/2019/04/cropped-500px-logo-photography-social-media-design-thumb-192x192.jpg")!
    )

    XCTAssertEqual(
      RSSTools.getSiteNameOf(html: content)!.string,
      NonEmptyString("500px")!.string
    )
  }

  func test_Get_First_Image() throws {
    let fileName = "wadetregaskis-com--a-brief-introduction-to-type-memory-layout-in-swift.html"
    let content = Self.getStringFrom(fileName: fileName)
    XCTAssertEqual(
      RSSTools.getFirstImageOf(html: content),
      URL(string: "https://wadetregaskis.com/wp-content/uploads/2023/12/Blank-pixel.png")
    )

    let fileName1 = "swift-org--blog-summer-of-code-2023-summary.html"
    let content1 = Self.getStringFrom(fileName: fileName1)
    XCTAssertEqual(
      RSSTools.getFirstImageOf(html: content1),
      URL(string: "https://www.gravatar.com/avatar/03cb20b97f6a14701c24c4e088b6af87?s=64&d=mp")
    )

    let fileName2 = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let content2 = Self.getStringFrom(fileName: fileName2)
    XCTAssertEqual(
      RSSTools.getFirstImageOf(html: content2),
      URL(string: "https://www.facebook.com/tr?id=324942534599956&ev=PageView&noscript=1")
    )
  }

  static private func getStringFrom(fileName: String) -> String {
    /*
     can be broken if moving related files
     */
    let filePath = URL(string: #filePath)!
      .deletingLastPathComponent()
      .appendingPathComponent("HTMLFiles/\(fileName)")
      .absoluteString

    return try! String(contentsOfFile: filePath)
  }
}
