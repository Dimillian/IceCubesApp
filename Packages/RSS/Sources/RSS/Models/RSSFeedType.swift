//
//  RSSFeedType.swift
//
//
//  Created by Duong Thai on 07/03/2024.
//

import RSParser

enum RSSFeedType: String, Codable {
  case rss
  case atom
  case jsonFeed
  case rssInJSON
  case unknown
  case notAFeed

  init(_ parsedFeedType: FeedType) {
    switch parsedFeedType {
    case .rss: self = .rss
    case .atom: self = .atom
    case .jsonFeed: self = .jsonFeed
    case .rssInJSON: self = .rssInJSON
    case .unknown: self = .unknown
    case .notAFeed: self = .notAFeed
    }
  }
}
