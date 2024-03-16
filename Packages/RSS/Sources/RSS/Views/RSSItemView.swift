//
//  RSSItemView.swift
//
//
//  Created by Duong Thai on 03/03/2024.
//

import SwiftUI
import StatusKit
import DesignSystem
import Env

@MainActor
struct RSSItemView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @ObservedObject private var item: RSSItem
  @State private var showAlert = false

  @State private var isRead: Bool // A workaround because SwiftUI doesn't animate on Core Data model changes.

  private var contentPadding: CGFloat {
    theme.avatarPosition == .top
    ? 0
    : AvatarView.FrameConfig.status.width + .statusColumnsSpacing
  }

  init(_ viewModel: RSSItem) {
    self.item = viewModel
    self._isRead = State(initialValue: viewModel.isRead)
  }

  var body: some View {
    if isRead {
      collapsedView()
    } else {
      VStack(alignment: .leading, spacing: .statusComponentSpacing) {
        headerView()
        bodyView()
        actionsView(url: item.url)
      }
    }
  }

  @ViewBuilder
  private func collapsedView() -> some View {
      HStack {
        Button(action: {
          if let url = item.url {
            _ = routerPath.handle(url: url)
          } else {
            showAlert = true
          }
        }, label: {
          HStack {
            AvatarView(item.feed?.iconURL ?? item.feed?.faviconURL, config: .list)
              .hoverEffect()
              .opacity(0.5)
              .frame(width: AvatarView.FrameConfig.status.width)
            
            VStack(alignment: .leading, spacing: 2) {
              Text(item.title ?? "no title")
                .foregroundColor(.secondary)
                .font(.scaledFootnote)
                .fontWeight(.semibold)
                .lineLimit(1)
              
              Text(item.date ?? .now, style: .offset)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
          }
        })
        .buttonStyle(.plain)
        .alert("rss.item.url.unavailable", isPresented: $showAlert) {
          Button("rss.item.url.unavailable.action.OK") { showAlert = false }
        } message: {
          Text("rss.item.url.unavailable.message")
        }

      Button {
        withAnimation {
          do {
            // MOVING `withAnimation` INTO HERE WILL DISABLE ANIMATIONS
            item.isRead = false
            try item.managedObjectContext?.save()
          } catch {
            debugPrint("Failed to save `RSSItem.isRead`.")
            item.managedObjectContext?.refresh(item, mergeChanges: false)
          }

          isRead = item.isRead
        }
      } label: {
        Image(systemName: "eye")
          .foregroundColor(.secondary)
          .font(.scaledFootnote)
          .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 0))
      }
    }
  }

  @ViewBuilder
  private func actionsView(url: URL?) -> some View {
    if let url = item.url {
      HStack {
        Button {
          routerPath.presentedSheet = .quoteLinkStatusEditor(link: url)
        } label: {
          Image(systemName: "paperplane")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }

        ShareLink(
          item: url,
          subject: Text(item.title ?? ""),
          message: Text(item.summary ?? "")
        ) {
          Image(systemName: "square.and.arrow.up")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }

        Button {
          withAnimation {
            do {
              // MOVING `withAnimation` INTO HERE WIll DISABLE ANIMATIONS
              item.isRead = true
              try item.managedObjectContext?.save()
            } catch {
              debugPrint("Failed to save `RSSItem.isRead`.")
              item.managedObjectContext?.refresh(item, mergeChanges: false)
            }

            isRead = item.isRead
          }
        } label: {
          Image(systemName: "eye")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .zIndex(1)
      }
      .padding(.leading, contentPadding)
      .buttonStyle(.borderless)
#if targetEnvironment(macCatalyst)
      .font(.scaledBody)
#else
      .font(.body)
      .dynamicTypeSize(.large)
#endif
    }
  }

  private func headerView() -> some View {
    HStack {
      AvatarView(item.feed?.iconURL ?? item.feed?.faviconURL, config: .status)
        .hoverEffect()

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 2) {
            Text(item.feed?.feedURL?.host() ?? "")
              .foregroundColor(theme.labelColor)
            Image(systemName: "dot.radiowaves.up.forward")
              .foregroundColor(theme.tintColor)
          }
          .font(.scaledSubheadline)
          .fontWeight(.semibold)
          .lineLimit(1)

          Text(item.authorsAsString ?? item.feed?.feedURL?.host() ?? "")
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        Text(item.date ?? .now, style: .offset)
          .font(.scaledFootnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.bottom, .statusComponentSpacing)
  }

  private func bodyView() -> some View {
    Button(action: {
      if let url = item.url {
        _ = routerPath.handle(url: url)
      } else {
        showAlert = true
      }
    }, label: {
      VStack(alignment: .leading, spacing: .statusComponentSpacing) {
        if
          let previewImageURL = item.previewImageURL
        {
          let width = item.previewImageWidth
          let height = item.previewImageHeight
          RSSPreviewImage(url: previewImageURL, originalSize: CGSize(width: width, height: height))
        }

        Text(item.title ?? "no title")
          .font(.scaledHeadline)
          .lineLimit(2)
          .padding(.vertical, .statusComponentSpacing)

        Text(item.summary ?? "")
          .font(.scaledBody)
          .lineSpacing(CGFloat(theme.lineSpacing))
          .lineLimit(10)
      }
      .padding(.leading, contentPadding)
    })
    .buttonStyle(.plain)
    .alert("rss.item.url.unavailable", isPresented: $showAlert) {
      Button("rss.item.url.unavailable.action.OK") { showAlert = false }
    } message: {
      Text("rss.item.url.unavailable.message")
    }
  }
}

