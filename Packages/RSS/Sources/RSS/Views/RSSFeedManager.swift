//
//  RSSFeedManager.swift
//
//
//  Created by Duong Thai on 12/3/24.
//

import SwiftUI
import DesignSystem

public struct RSSFeedManager: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) private var moContext
  @FetchRequest(sortDescriptors: [SortDescriptor(\.title, order: .reverse)])
  private var feeds: FetchedResults<RSSFeed>

  public var body: some View {
    NavigationStack{
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
}

#Preview {
  RSSFeedManager()
}
