//
//  SwiftUIView.swift
//  
//
//  Created by Duong Thai on 12/3/24.
//

import SwiftUI
import DesignSystem

struct RSSFeedView: View {
  @ObservedObject private var feed: RSSFeed
  @Environment(Theme.self) private var theme

  private var items: ArraySlice<RSSItem> {
    feed.toRSSItems()
      .sorted { $0.date > $1.date }
      .prefix(5)
  }

  private var contentPadding: CGFloat {
    theme.avatarPosition == .top
    ? 0
    : AvatarView.FrameConfig.status.width + .statusColumnsSpacing
  }

  var body: some View {
    VStack(alignment: .leading, spacing: .statusComponentSpacing) {
      headerView()
      VStack(alignment: .leading, spacing: theme.lineSpacing) {
        if let feedDescription = feed.feedDescription {
          Text(feedDescription)
        }
        Text("rss.rssFeedManager.latestItemsSection.label")
          .font(.scaledFootnote)
          .fontWeight(.bold)
          .lineLimit(1)
        ForEach(items) { item in
          HStack(alignment: .lastTextBaseline) {
            Text(" ⋅ \(item.title ?? "No Title")")
            Spacer()
            Text(item.date ?? .now, style: .offset)
              .foregroundStyle(.secondary)
          }
        }
        .font(.scaledFootnote)
        .lineLimit(1)
      }

      HStack {
        Button {
          feed.isShowing.toggle()
        } label: {
          Image(systemName: "eye")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }

        Divider()

        Button {
          feed.managedObjectContext!.delete(feed)
        } label: {
          Image(systemName: "trash")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
      }
      .padding(.leading, contentPadding)
      .padding(.top, 6)
      .buttonStyle(.borderless)
#if targetEnvironment(macCatalyst)
      .font(.scaledBody)
#else
      .font(.body)
      .dynamicTypeSize(.large)
#endif
    }
    .opacity(feed.isShowing ? 1 : 0.5)
  }


  public init(_ feed: RSSFeed) {
    self.feed = feed
  }

  private func headerView() -> some View {
    HStack {
      AvatarView(feed.iconURL ?? feed.faviconURL, config: .status)
        .accessibility(addTraits: .isButton)
        .contentShape(Circle())
        .hoverEffect()

      HStack(alignment: .bottom) {
        HStack(spacing: 2) {
          Text(feed.feedURL?.host() ?? "")
            .foregroundColor(theme.labelColor)
          Image(systemName: "dot.radiowaves.up.forward")
            .foregroundColor(theme.tintColor)
        }
        .font(.scaledSubheadline)
        .fontWeight(.semibold)
        .lineLimit(1)
      }
    }
  }
}
