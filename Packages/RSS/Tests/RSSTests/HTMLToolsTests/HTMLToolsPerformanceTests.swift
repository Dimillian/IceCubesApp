//
//  HTMLToolsPerformanceTests.swift
//  
//
//  Created by Duong Thai on 03/03/2024.
//

import XCTest
@testable import RSS
import SwiftSoup

final class HTMLToolsPerformanceTests: XCTestCase {
  func test_Performance_SwiftSoup() {
    let fileName = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let content = Self.getStringFrom(fileName: fileName)

    measure {
      _ = try! SwiftSoup.parse(content)
    }
  }

  func test_Performance_Regex() {
    let fileName = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let sourceURL = URL(string: "https://iso.500px.com/10-chilly-new-photos-from-500px-licensing/")!
    let content = Self.getStringFrom(fileName: fileName)

    measure {
      _ = RSSTools.getTitleOf(html: content)!.string
      _ = RSSTools.getContentTypeOf(html: content)!.string
      _ = RSSTools.getPreviewImageOf(html: content)!
      _ = RSSTools.getURLOf(html: content)!
      _ = RSSTools.getFaviconOf(html: content, sourceURL: sourceURL)!
      _ = RSSTools.getSiteNameOf(html: content)!.string
    }
  }

  func test_Performance_Convert_HTML_To_NSAttributedString_Without_Media() {
    let fileName = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let content = Self.getStringFrom(fileName: fileName)

    measure {
      _ = RSSTools.convert(content, baseURL: nil)
    }
  }

  func test_Performance_Convert_HTML_To_NSAttributedString_With_Media() {
    let fileName = "iso-500px-com--10-chilly-new-photos-from-500px-licensing.html"
    let content = Self.getStringFrom(fileName: fileName)

    measure {
      _ = RSSTools.convert(content, baseURL: nil, withMedia: true)
    }
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
