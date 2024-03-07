//
//  RSSItem+SendableData.swift
//  
//
//  Created by Duong Thai on 07/03/2024.
//

import CoreData
import RSParser
import SwiftUI

extension RSSItem {
  public struct SendableData: Sendable {
    let parsedItem: ParsedItem
    let feedURL: URL
    let feedAuthors: Set<ParsedAuthor>
    let previewImageData: (url: URL, size: CGSize)?

    init(parsedItem: ParsedItem, feedURL: URL, feedAuthors: Set<ParsedAuthor>) {
      self.parsedItem = parsedItem
      self.feedURL = feedURL
      self.feedAuthors = feedAuthors

      self.previewImageData = parsedItem.getRSSPreviewImageData()
    }
  }
}

extension ParsedAuthor: @unchecked Sendable {} // checked

extension ParsedItem {
  func getRSSSummary() -> String {
    let _summary = if let summary = self.summary {
      summary.replacingOccurrences(of: "\n\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } else if let contentText = self.contentText {
      contentText
        .replacingOccurrences(of: "\n\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } else if
    let contentHTML = self.contentHTML,
        let contentHTML = HTMLTools.convert(contentHTML, baseURL: self.getRSSURL())?.string
    {
      contentHTML
        .replacingOccurrences(of: "\n\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      ""
    }

    return _summary
      .replacingOccurrences(of: "\n\n", with: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func getRSSPreviewImageData() -> (url: URL, size: CGSize)? {
    if
      let imageURLString = self.imageURL,
      let imageURL = URL(string: imageURLString),
      let imageData = try? Data(contentsOf: imageURL),
      let image = UIImage(data: imageData)
    {
      (url: imageURL, size: image.size)
    } else if
      let contentHTML = self.contentHTML,
      let imageURL = HTMLTools.getFirstImageOf(html: contentHTML),
      let imageData = try? Data(contentsOf: imageURL),
      let image = UIImage(data: imageData)
    {
      (url: imageURL, size: image.size)
    } else {
      nil
    }
  }

  func getRSSURL() -> URL? {
    if let url = self.url {
      URL(string: url)
    } else if let externalURL = self.externalURL {
      URL(string: externalURL)
    } else if let uniqueURL = URL(string: self.uniqueID) {
      uniqueURL
    } else {
      nil
    }
  }

  func getRSSDate() -> Date {
    self.dateModified ?? self.datePublished ?? .now
  }

  func getRSSAuthors(
    context: NSManagedObjectContext,
    feedAuthors: Set<ParsedAuthor>,
    feedURL: URL
  ) -> NSSet {
    let authors = self.authors?.union(feedAuthors)
      .compactMap {
        RSSAuthor(context: context, parsedAuthor: $0, feedURL: feedURL)
      }
    ?? []

    return NSSet(array: authors)
  }
}
