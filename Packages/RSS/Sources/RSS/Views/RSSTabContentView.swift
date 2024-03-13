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
  @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)],
                predicate: NSPredicate(format: "feed.isShowing == TRUE"))
  private var items: FetchedResults<RSSItem>

  @Environment(\.managedObjectContext) private var moContext
  @State private var isLoading = true

  @Environment(Client.self) private var client
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath


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
      Label("tab.rss.contentUnavailableView.title", systemImage: "dot.radiowaves.up.forward")
    } description: {
      Text("tab.rss.contentUnavailableView.description")
    } actions: {
      Button {
        Task { @MainActor in
          routerPath.presentedSheet = SheetDestination.rssFeedManager
          HapticManager.shared.fireHaptic(.buttonPress)
        }
      } label: {
        Text("tab.rss.contentUnavailableView.action.goToRSSManager")
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
      .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { notification in
        let userInfo = notification.userInfo ?? [:]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [moContext])
      }
      .toolbar {
        makeToolbarItems()
      }
    }
  }
}
