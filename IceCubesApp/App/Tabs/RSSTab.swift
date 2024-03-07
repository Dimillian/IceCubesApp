//
//  RSSTab.swift
//  IceCubesApp
//
//  Created by Duong Thai on 26/02/2024.
//

import SwiftUI
import RSParser
import SwiftSoup
import DesignSystem
import RSS
import Env

@MainActor
public struct RSSTab: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
  private var items: FetchedResults<RSSItem>

  @Environment(\.managedObjectContext) private var moContext
  @State private var isLoading = true

  @State private var showAlert = false
  @State private var routerPath = RouterPath()

  public init() {}

  public var body: some View {
    NavigationStack {
      if isLoading {
        ProgressView()
      } else {
        List {
          ForEach(items) { i in
            Button(action: {
              if let url = i.url {
                _ = routerPath.handle(url: url)
              } else {
                showAlert = true
              }
            }, label: {
              RSSItemView(i)
            })
            .buttonStyle(.plain)
            .alert("rss.item.url.unavailable", isPresented: $showAlert) {
              Button("rss.item.url.unavailable.action.OK") { showAlert = false }
            } message: {
              Text("rss.item.url.unavailable.message")
            }
          }
        }
        .listStyle(PlainListStyle())
      }
    }
    // TODO: remove this
    .onDisappear {
      for f in items { moContext.delete(f) }
    }
    .task {
      isLoading = true

      let feedURLs = [
        "https://www.swift.org/atom.xml",
        "https://wadetregaskis.com/feed",
        "https://121clicks.com/feed",
        "https://iso.500px.com/feed/",
      ]

      let sendableFeeds = await Task<[RSSFeed.SendableData], Never>.detached(priority: .userInitiated, operation: {
        return await withTaskGroup(of: RSSFeed.SendableData?.self) { taskGroup in
          for fURL in feedURLs {
            taskGroup.addTask {
              guard
                let url = URL(string: fURL),
                let data = try? Data(contentsOf: url),
                let feed = try? FeedParser.parse(ParserData(url: fURL, data: data))
              else { return nil }

              return RSSFeed.SendableData(parsedFeed: feed, sourceURL: url)
            }
          }

          var _feeds = [RSSFeed.SendableData]()
          for await f in taskGroup {
            if let f { _feeds.append(f) }
          }

          return _feeds
        }
      }).value

      let rssFeeds = sendableFeeds.compactMap {
        (feed: RSSFeed(context: moContext, sendableData: $0), sendableFeed: $0)
      }

      for feed in rssFeeds {
        let sendableFeed = feed.sendableFeed
        let sendableItems = await Task.detached {
          await sendableFeed.getSendableItemData()
        }.value

        let items = sendableItems.compactMap {
          RSSItem(context: moContext, sendableData: $0)
        }

        feed.feed.items = NSSet(array: items)
      }

      isLoading = false
    }
  }
}
