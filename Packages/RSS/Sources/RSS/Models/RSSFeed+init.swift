//
//  RSSFeed+init.swift
//
//
//  Created by Duong Thai on 05/03/2024.
//

import CoreData
import RSParser

extension RSSFeed {
  convenience init(
    context: NSManagedObjectContext,
    sendableData: RSSFeed.SendableData
  ) {
    self.init(context: context)

    let _feedURL = sendableData.parsedFeed.getRSSFeedURL(sourceURL: sendableData.sourceURL)
    self.feedURL = _feedURL

    self.homePageURL = if let homePageURL = sendableData.parsedFeed.homePageURL {
      URL(string: homePageURL)
    } else {
      nil
    }

    self.type = RSSFeedType(sendableData.parsedFeed.type).rawValue
    self.title = sendableData.parsedFeed.title
    self.feedDescription = sendableData.parsedFeed.feedDescription

    self.nextURL = if let nextURL = sendableData.parsedFeed.nextURL {
      URL(string: nextURL)
    } else {
      nil
    }

    self.iconURL = if let iconURLString = sendableData.parsedFeed.iconURL {
      URL(string: iconURLString)
    } else if let iconURL = sendableData.enhancedIconURL {
      iconURL
    }else {
      nil
    }

    self.faviconURL = if let faviconURLString = sendableData.parsedFeed.faviconURL {
      URL(string: faviconURLString)
    } else if let faviconURL = sendableData.enhancedFaviconURL {
      faviconURL
    } else {
      nil
    }

    self.expired = sendableData.parsedFeed.expired
    self.isShowing = true
  }
}
