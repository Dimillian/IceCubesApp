//
//  RSSItem+init.swift
//
//
//  Created by Duong Thai on 05/03/2024.
//

import CoreData

extension RSSItem {
  convenience init?(
    context: NSManagedObjectContext,
    sendableData: RSSItem.SendableData
  ) {
    self.init(context: context)

    let title = sendableData.parsedItem.title ?? ""
    let summary = sendableData.parsedItem.getRSSSummary()
    let previewImageData = sendableData.previewImageData

    if
      title.isEmpty,
      summary.isEmpty,
      previewImageData == nil
    { return nil }

    self.title = title
    self.summary = summary

    if let previewImageData {
      self.previewImageURL = previewImageData.url
      self.previewImageWidth = previewImageData.size.width
      self.previewImageHeight = previewImageData.size.height
    }

    self.uniqueID = sendableData.parsedItem.uniqueID
    self.url = sendableData.parsedItem.getRSSURL()
    self.date = sendableData.parsedItem.getRSSDate()
    self.authors = sendableData.parsedItem
      .getRSSAuthors(context: context, feedAuthors: sendableData.feedAuthors, feedURL: sendableData.feedURL)

    self.tags = NSSet(set: sendableData.parsedItem.tags ?? [])
    self.isRead = false
  }

  var authorsAsString: String? {
    if authors?.allObjects.isEmpty ?? true {
      nil
    } else {
      (authors?.allObjects as? [RSSAuthor])?.map {
        $0.displayName ?? ""
      }
      .sorted { $0 < $1 }
      .joined(separator: " ⸱ ")
    }
  }
}
