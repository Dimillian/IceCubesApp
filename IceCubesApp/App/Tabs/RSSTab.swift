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
import Network

@MainActor
public struct RSSTab: View {
  @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
  private var items: FetchedResults<RSSItem>

  @Environment(\.managedObjectContext) private var moContext
  @State private var isLoading = true

  @Environment(Client.self) private var client
  @State private var routerPath = RouterPath()

  public init() {}

  public var body: some View {
    NavigationStack {
      List {
        if isLoading {
          ProgressView()
        } else {
          ForEach(items) { item in
            RSSItemView(item)
          }
        }
      }
      .navigationTitle("tab.rss")
      .navigationBarTitleDisplayMode(.inline)
      .listStyle(PlainListStyle())
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
      .toolbar {
        if client.isAuth {
          ToolbarTab(routerPath: $routerPath)
        }
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
        "https://www.computerenhance.com/feed",
        "https://wadetregaskis.com/feed",
        "https://iso.500px.com/feed/",
      ].compactMap { URL(string: $0) }

      await RSSTools.load(feedURLs: feedURLs, into: moContext)

      isLoading = false
    }
    .withSafariRouter()
    .environment(routerPath)
  }
}
