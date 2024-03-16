//
//  RSSFeedManager.swift
//
//
//  Created by Duong Thai on 12/3/24.
//

import SwiftUI
import DesignSystem
import Env

public struct RSSFeedManager: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var moContext
  @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .reverse)])
  private var feeds: FetchedResults<RSSFeed>

  @State private var routerPath = RouterPath()

  public var body: some View {
    NavigationStack{
      Group {
        if feeds.isEmpty {
          makeContentUnavailableView()
        } else {
          makeFeedList()
        }
      }
      .listStyle(PlainListStyle())
      .navigationTitle("rss.rssFeedManager.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
            moContext.rollback()
          } label: {
            Image(systemName: "xmark")
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink {
            RSSAddNewFeed(context: .manager)
          } label: {
            Image(systemName: "plus")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("rss.rssFeedManager.action.done") {
            dismiss()
            try? moContext.save()
          }
        }
      }
    }
    .onDisappear { moContext.rollback() }
    .environment(Theme.shared)
  }

  public init() {}

  private func makeContentUnavailableView() -> some View {
    ContentUnavailableView {
      Label("rss.manager.contentUnavailableView.title", systemImage: "dot.radiowaves.up.forward")
    } description: {
      Text("rss.manager.contentUnavailableView.description")
    } actions: {
      NavigationLink {
        RSSAddNewFeed(context: .manager)
      } label: {
        Text("rss.manager.contentUnavailableView.action.addNewFeed")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private func makeFeedList() -> some View {
    List {
      ForEach(feeds) { feed in
        RSSFeedView(feed)
      }
      .onDelete { indices in
        for index in indices {
          moContext.delete(feeds[index])
        }
      }
    }
  }
}

#Preview {
  RSSFeedManager()
}
