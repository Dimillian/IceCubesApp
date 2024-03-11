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
  @Environment(UserPreferences.self) private var userPreferences
  @State private var routerPath = RouterPath()

  public init() {}

  public var body: some View {
    NavigationStack {
      List {
          ForEach(items) { item in
            RSSItemView(item)
          }
      }
      .navigationTitle("tab.rss")
      .navigationBarTitleDisplayMode(.inline)
      .listStyle(PlainListStyle())
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
      .toolbar {
        if client.isAuth {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              Task { @MainActor in
                routerPath.presentedSheet = SheetDestination.addNewRSSFeed
                HapticManager.shared.fireHaptic(.buttonPress)
              }
            } label: {
              Image(systemName: "plus")
                .accessibilityLabel("accessibility.tabs.timeline.new-post.label")
                .accessibilityInputLabels([
                  LocalizedStringKey("accessibility.tabs.timeline.new-post.label"),
                  LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel1"),
                  LocalizedStringKey("accessibility.tabs.timeline.new-post.inputLabel2"),
                ])
                .offset(y: -2)
            }
          }
        }
      }
    }
    .withSafariRouter()
    .environment(routerPath)
  }
}
