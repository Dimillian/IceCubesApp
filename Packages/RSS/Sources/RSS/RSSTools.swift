//
//  RSSTools.swift
//  IceCubesApp
//
//  Created by Duong Thai on 02/03/2024.
//

import RSParser
import CoreData

enum RSSTools {
  static func convert(_ html: String, baseURL _: URL?, withMedia: Bool = false) -> NSAttributedString? {
    let string = if withMedia {
      html
    } else {
      html.replacing(
        /(<img.*?>|<video.*?<\/video>|<iframe.*?<\/iframe>)/,
        with: { _ in "" }
      )
    }

    let data = Data(string.utf8)
    return try? NSAttributedString(
      data: data,
      options: [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue,
      ],
      documentAttributes: nil
    )
  }

  static func getFaviconOf(html: String, sourceURL: URL) -> URL? {
    let pattern = MetadataPattern.favicon
    guard let match = html.firstMatch(of: pattern),
          let string = NonEmptyString(String(match.1)),
          let url = URL(string: string.string)
    else { return nil }

    if url.host() != nil {
      return url
    } else if let host = sourceURL.host() {
      return URL(string: "https://" + host + url.absoluteString)
    } else {
      return nil
    }
  }

  static func getIconOf(html: String, sourceURL: URL) -> URL? {
    let pattern = MetadataPattern.icon
    let matches = html.matches(of: pattern)
    let icons: [Icon] = matches
      .compactMap {
        guard let url = URL(string: String($0.1)) else { return nil }

        guard let d_w = Double(String($0.2)) else { return nil }
        let width = CGFloat(d_w)

        guard let h_w = Double(String($0.3)) else { return nil }
        let height = CGFloat(h_w)

        return Icon(url: url, with: width, height: height)
      }
      .sorted { $0.with > $1.with }

    return icons.first?.url
  }

  static func getTitleOf(html: String) -> NonEmptyString? {
    let pattern = MetadataPattern.title
    guard let match = html.firstMatch(of: pattern) else { return nil }
    return NonEmptyString(String(match.1))
  }

  static func getContentTypeOf(html: String) -> NonEmptyString? {
    let pattern = MetadataPattern.type
    guard let match = html.firstMatch(of: pattern) else { return nil }
    return NonEmptyString(String(match.1))
  }

  static func getPreviewImageOf(html: String) -> URL? {
    let pattern = MetadataPattern.image
    guard let match = html.firstMatch(of: pattern),
          let string = NonEmptyString(String(match.1)),
          let url = URL(string: string.string)
    else { return nil }

    return url
  }

  static func getURLOf(html: String) -> URL? {
    let pattern = MetadataPattern.url
    guard let match = html.firstMatch(of: pattern),
          let url = URL(string: String(match.1))
    else { return nil }

    return url
  }

  static func getSiteNameOf(html: String) -> NonEmptyString? {
    let pattern = MetadataPattern.siteName
    guard let match = html.firstMatch(of: pattern) else { return nil }
    return NonEmptyString(String(match.1))
  }

  static func getFirstImageOf(html: String, baseURL: URL?) -> URL? {
    guard let match = html.firstMatch(of: /<img[\s\S]+?src="(.+?)"/),
          let url =  URL(string: String(match.1))
    else { return nil }

    return if url.host != nil {
      url
    } else if let host = baseURL?.host() {
      URL(string: "https://\(host)\(url.absoluteString)")
    } else {
      nil
    }
  }

  static func getFeedData(from feedURL: URL) async -> RSSFeed.SendableData? {
    guard
      let data = try? Data(contentsOf: feedURL),
      let feed = try? FeedParser.parse(ParserData(url: feedURL.absoluteString, data: data))
    else { return nil }

    return RSSFeed.SendableData(parsedFeed: feed, sourceURL: feedURL)
  }

  static func getFeedsData(from feedURLs: [URL]) async -> [RSSFeed.SendableData] {
    return await Task<[RSSFeed.SendableData], Never>.detached {
      return await withTaskGroup(of: RSSFeed.SendableData?.self) { taskGroup in
        for url in feedURLs {
          taskGroup.addTask {
            return await getFeedData(from: url)
          }
        }

        var _feeds = [RSSFeed.SendableData]()
        for await f in taskGroup {
          if let f { _feeds.append(f) }
        }

        return _feeds
      }
    }.value
  }

  @MainActor
  static func load(feedURLs: [URL], into context: NSManagedObjectContext) async -> [RSSFeed] {
    let sendableFeeds = await RSSTools.getFeedsData(from: feedURLs)

    let feedPairs = sendableFeeds.compactMap {
      (feed: RSSFeed(context: context, sendableData: $0), sendableFeed: $0)
    }

    for pair in feedPairs {
      let sendableFeed = pair.sendableFeed
      let sendableItems = await Task.detached {
        await sendableFeed.getSendableItemData()
      }.value

      let items = sendableItems.compactMap {
        RSSItem(context: context, sendableData: $0)
      }

      pair.feed.items = NSSet(array: items)
    }

    return feedPairs.map { $0.feed }
  }
  
  @MainActor
  static func load(feedURL: URL, into context: NSManagedObjectContext) async -> RSSFeed? {
    let sendableFeed = await Task.detached {
      await RSSTools.getFeedData(from: feedURL)
    }.value

    guard let sendableFeed else { return nil }

    let rssFeed = RSSFeed(context: context, sendableData: sendableFeed)

    let sendableItems = await Task.detached {
      await sendableFeed.getSendableItemData()
    }.value

    let rssItems = sendableItems.compactMap {
      RSSItem(context: context, sendableData: $0)
    }
    rssFeed.items = NSSet(array: rssItems)
    return rssFeed
  }

  @MainActor
  static func load(feedURL: URL) async -> Void? {
    await Task<()?, Never>.detached {
      guard
        let sendableFeed = await RSSTools.getFeedData(from: feedURL)
      else { return nil }

      let context = await RSSDataController.shared.container.newBackgroundContext()
      context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
      let sendableItems = await sendableFeed.getSendableItemData()

      let rssFeed = RSSFeed(context: context, sendableData: sendableFeed)

      let rssItems = sendableItems.compactMap {
        RSSItem(context: context, sendableData: $0)
      }
      for item in rssItems { item.feed = rssFeed }

      return try? context.save()
    }.value
  }

  @MainActor
  static func fetchFeed(url: URL) async -> RSSFeed? {
    let request: NSFetchRequest<RSSFeed> = {
      let request = RSSFeed.fetchRequest()
      request.fetchLimit = 1
      request.predicate = NSPredicate(format: "%K = %@",
                                      #keyPath(RSSFeed.feedURL),
                                      url as CVarArg)
      request.relationshipKeyPathsForPrefetching = ["items"]
      return request
    }()

    let context = RSSDataController.shared.viewContext
    guard let feed = (try? context.fetch(request))?.first else { return nil }
    return feed
  }

  @MainActor
  static func update(feedURL: URL) async {
    /*
     * TODO: use task local
     */

    let request: NSFetchRequest<RSSFeed> = {
      let request = RSSFeed.fetchRequest()
      request.fetchLimit = 1
      request.predicate = NSPredicate(format: "%K = %@",
                                      #keyPath(RSSFeed.feedURL),
                                      feedURL as CVarArg)
      request.relationshipKeyPathsForPrefetching = ["items"]
      return request
    }()

    let context = RSSDataController.shared.backgroundContext
    guard let feed = (try? context.fetch(request))?.first else { return }

    let itemIDs = feed.toRSSItems().compactMap { $0.uniqueID! }
    print(feed)

    if Task.isCancelled { return }

    let sendableFeed = await Task.detached {
      await RSSTools.getFeedData(from: feedURL)
    }.value
    if Task.isCancelled { return }

    guard let sendableFeed else { return }

    let sendableItems = await Task.detached {
      await sendableFeed.getSendableItemData()
    }.value
    if Task.isCancelled { return }

    let items: [RSSItem] = sendableItems.compactMap {
      if itemIDs.contains($0.parsedItem.uniqueID) { nil }
      else { RSSItem(context: context, sendableData: $0) }
    }
    if Task.isCancelled { return }

    for item in items { item.feed = feed }

    do {
      try context.save()
      print("Auto-updated for \(feedURL.absoluteString): Saved \(items.count) item(s).")
    } catch {
      print(error.localizedDescription)
    }
  }

  final class AutoUpdater {
    private let feedURLs: [URL]
    private let autoUpdatingTask: Task<Void, Never>

    init(feedURLs: [URL]) {
      self.feedURLs = feedURLs
      self.autoUpdatingTask = Task.detached {
        print("Updating feed(s)' URL(s): \(feedURLs)")
        await withTaskGroup(of: Void.self) { taskGroup in
          for url in feedURLs {
            taskGroup.addTask {
              repeat {
                await RSSTools.update(feedURL: url)
                try? await Task.sleep(for: .seconds(30*60))
              } while !Task.isCancelled
              print("The auto-updating task for \(url.absoluteString) has been canceled.")
            }
          }
        }
      }
    }

    deinit {
      print("deinit task")
      autoUpdatingTask.cancel()
    }
  }
}

private struct Icon {
  let url: URL
  let with: CGFloat
  let height: CGFloat
}

private enum MetadataPattern {
  static var favicon: Regex<(Substring, Substring)> {
    /<link[\s\S]*?rel=\".*?icon\"[\s\S]+?href=\"(.+?)\"/
  }
  static var icon: Regex<(Substring, Substring, Substring, Substring)> {
    /<link[\s\S]*?rel=\".*?icon\"[\s\S]+?href=\"(.+?)\".+?sizes=\"(\d+?)x(\d+?)"/
  }
  static var title: Regex<(Substring, Substring)> {
    /<meta[\s\S]*?property=\"og:title\" content=\"(.+?)\"/
  }
  static var type: Regex<(Substring, Substring)> {
    /<meta[\s\S]*?property=\"og:type\" content=\"(.+?)\"/
  }
  static var image: Regex<(Substring, Substring)> {
    /<meta[\s\S]*?property=\"og:image\" content=\"(.+?)\"/
  }
  static var url: Regex<(Substring, Substring)> {
    /<meta[\s\S]*?property=\"og:url\" content=\"(.+?)\"/
  }
  static var siteName: Regex<(Substring, Substring)> {
    /<meta[\s\S]*?property=\"og:site_name\" content=\"(.+?)\"/
  }
}

public struct NonEmptyString {
  let string: String

  init?(_ string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return nil } else { self.string = trimmed }
  }
}

extension ParsedItem: @unchecked Sendable {} // checked
