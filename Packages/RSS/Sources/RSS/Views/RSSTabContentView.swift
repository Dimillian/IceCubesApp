//
//  RSSTabContentView.swift
//
//
//  Created by Duong Thai on 13/3/24.
//

import SwiftUI
import RSParser
import SwiftSoup
import DesignSystem
import Env
import Network
import AppAccount
import CoreData

public struct RSSTabContentView: View {
  @FetchRequest(sortDescriptors: [],
                predicate: NSPredicate(format: "isShowing == true"))
  private var feeds: FetchedResults<RSSFeed>
  private var items: [RSSItem] { feeds.toRSSItems().sorted { $0.date > $1.date } }

  @Environment(\.managedObjectContext) private var moContext
  @State private var autoUpdater: RSSTools.AutoUpdater? = nil

  @Environment(Client.self) private var client
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath

  public var body: some View {
    NavigationStack {
      Group {
        if items.isEmpty {
          makeContentUnavailableView()
        } else {
          makeItemList()
        }
      }
      .navigationTitle("tab.rss")
      .navigationBarTitleDisplayMode(.inline)
      .listStyle(PlainListStyle())
      .toolbar { makeToolbarItems() }
      .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { notification in
        let userInfo = notification.userInfo ?? [:]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [moContext])
      }
    }
    .task {
      // WARNING: DON'T REMOVE, THIS CODE IS FOR TESTING PURPOSE.
      //        try? await Task.sleep(for: .seconds(5))
      //        let _context = RSSDataController.shared.viewContext
      //        for item in feeds.toRSSItems() { _context.delete(item) }
      //        try! _context.save()

      autoUpdater = RSSTools.AutoUpdater(feedURLs: feeds.compactMap { $0.feedURL })
    }
    // FIXME: Why doesn't `AutoUpdater.deinit` never call?
    //        This code triggers `AutoUpdater.deinit`.
    .onDisappear { autoUpdater = nil }
  }

  public init() {}

  @ToolbarContentBuilder
  private func makeToolbarItems() -> some ToolbarContent {
    if client.isAuth {
      ToolbarItem(placement: .navigationBarLeading) {
        AppAccountsSelectorView(routerPath: routerPath)
      }

      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task { @MainActor in
            routerPath.presentedSheet = SheetDestination.rssFeedManager
            HapticManager.shared.fireHaptic(.buttonPress)
          }
        } label: {
          Image(systemName: "list.bullet.rectangle.portrait")
        }
      }

      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          Task { @MainActor in
            routerPath.presentedSheet = SheetDestination.addNewRSSFeed
            HapticManager.shared.fireHaptic(.buttonPress)
          }
        } label: {
          Image(systemName: "plus")
        }
      }
    }
  }

  private func makeContentUnavailableView() -> some View {
    ContentUnavailableView {
      Label("rss.tab.contentUnavailableView.title", systemImage: "dot.radiowaves.up.forward")
    } description: {
      Text("rss.tab.contentUnavailableView.description")
    } actions: {
      Button {
        Task { @MainActor in
          routerPath.presentedSheet = SheetDestination.rssFeedManager
          HapticManager.shared.fireHaptic(.buttonPress)
        }
      } label: {
        Text("rss.tab.contentUnavailableView.action.goToRSSManager")
      }
      .buttonStyle(.borderedProminent)

      Button {
        Task { @MainActor in
          routerPath.presentedSheet = SheetDestination.addNewRSSFeed
          HapticManager.shared.fireHaptic(.buttonPress)
        }
      } label: {
        Text("rss.tab.contentUnavailableView.action.addNewFeed")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private func makeItemList() -> some View {
    List {
      ForEach(items) { item in
        RSSItemView(item)
      }
    }
  }
}
