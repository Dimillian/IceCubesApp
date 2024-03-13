//
//  RSSFeed+SendableData.swift.swift
//
//
//  Created by Duong Thai on 07/03/2024.
//

import RSParser

extension RSSFeed {
  public struct SendableData: Sendable {
    let parsedFeed: ParsedFeed
    let sourceURL : URL
    let enhancedIconURL : URL?
    let enhancedFaviconURL : URL?

    init(parsedFeed: ParsedFeed, sourceURL: URL) {
      self.parsedFeed = parsedFeed
      self.sourceURL = sourceURL

      if parsedFeed.iconURL == nil && parsedFeed.faviconURL == nil {
        let pageURL: URL?
        let _feedURL = parsedFeed.getRSSFeedURL(sourceURL: sourceURL)

        if let homePageURL = URL(string: parsedFeed.homePageURL ?? "")
        {
          pageURL = homePageURL
        } else if
          let host = _feedURL.host,
          let scheme = _feedURL.scheme,
          let hostURL = URL(string: scheme + "://" + host)
        {
          pageURL = hostURL
        } else {
          pageURL = nil
        }

        if let pageURL,
           let pageData = try? Data(contentsOf: pageURL),
           let pageHTML = String(bytes: pageData, encoding: .utf8)
        {
          self.enhancedIconURL = RSSTools.getIconOf(html: pageHTML, sourceURL: pageURL)
          self.enhancedFaviconURL = RSSTools.getFaviconOf(html: pageHTML, sourceURL: pageURL)
        } else {
          self.enhancedIconURL = nil
          self.enhancedFaviconURL = nil
        }
      } else {
        self.enhancedIconURL = nil
        self.enhancedFaviconURL = nil
      }
    }

    private var parsedItems: [ParsedItem] { Array(self.parsedFeed.items) }

    func getSendableItemData() async -> [RSSItem.SendableData] {
      return await withTaskGroup(of: RSSItem.SendableData?.self) { taskGroup in
        var accumulatedItems = [RSSItem.SendableData]()

        for item in parsedItems {
          taskGroup.addTask {
            await Task.detached {
              RSSItem.SendableData(
                parsedItem: item,
                feedURL: self.sourceURL,
                feedAuthors: self.parsedFeed.authors ?? []
              )
            }.value
          }
        }

        for await i in taskGroup {
          if let i {
            accumulatedItems.append(i)
          }
        }

        return accumulatedItems
      }
    }

    func getSendableItemData(concurrentTaskThreshold: Int) async -> [RSSItem.SendableData] {
      return await withTaskGroup(of: RSSItem.SendableData?.self) { taskGroup in
        let subArrays = stride(from: 0, to: parsedItems.count, by: concurrentTaskThreshold)
          .map {
            parsedItems[$0..<min($0 + concurrentTaskThreshold, parsedItems.count)]
          }

        var accumulatedItems = [RSSItem.SendableData]()
        for s in subArrays {
          for item in s {
            taskGroup.addTask {
              await Task.detached {
                RSSItem.SendableData(
                  parsedItem: item,
                  feedURL: self.sourceURL,
                  feedAuthors: self.parsedFeed.authors ?? []
                )
              }.value
            }
          }
          for await i in taskGroup {
            if let i {
              accumulatedItems.append(i)
            }
          }
        }

        return accumulatedItems
      }
    }
  }
}

extension ParsedFeed: @unchecked Sendable {} // checked

extension ParsedFeed {
  func getRSSFeedURL(sourceURL: URL) -> URL {
    if
      let feedURL = self.feedURL,
      let url = URL(string: feedURL)
    { url } else { sourceURL }
  }
}
