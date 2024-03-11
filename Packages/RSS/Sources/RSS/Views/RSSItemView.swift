//
//  SwiftUIView.swift
//
//
//  Created by Duong Thai on 03/03/2024.
//

import SwiftUI
import StatusKit
import DesignSystem
import Env

@MainActor
public struct RSSItemView: View {
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @ObservedObject private var viewModel: RSSItem
  @State private var showAlert = false

  private var contentPadding: CGFloat {
    theme.avatarPosition == .top
    ? 0
    : AvatarView.FrameConfig.status.width + .statusColumnsSpacing
  }

  public init(_ viewModel: RSSItem) {
    self.viewModel = viewModel
  }

  public var body: some View {
    Button(action: {
      if let url = viewModel.url {
        _ = routerPath.handle(url: url)
      } else {
        showAlert = true
      }
    }, label: {
      VStack(alignment: .leading, spacing: .statusComponentSpacing) {
        headerView()
        bodyView()
        actionsView(url: viewModel.url)
      }
    })
    .buttonStyle(.plain)
    .alert("rss.item.url.unavailable", isPresented: $showAlert) {
      Button("rss.item.url.unavailable.action.OK") { showAlert = false }
    } message: {
      Text("rss.item.url.unavailable.message")
    }
  }

  @ViewBuilder
  private func actionsView(url: URL?) -> some View {
    if let url = viewModel.url {
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
          subject: Text(viewModel.title ?? ""),
          message: Text(viewModel.summary ?? "")
        ) {
          Image(systemName: "square.and.arrow.up")
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
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
      AvatarView(viewModel.feed?.iconURL ?? viewModel.feed?.faviconURL, config: .status)
        .accessibility(addTraits: .isButton)
        .contentShape(Circle())
        .hoverEffect()

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 2) {
            Text(viewModel.feed?.feedURL?.host() ?? "")
              .foregroundColor(theme.labelColor)
            Image(systemName: "dot.radiowaves.up.forward")
              .foregroundColor(theme.tintColor)
          }
          .font(.scaledSubheadline)
          .fontWeight(.semibold)
          .lineLimit(1)

          Text(viewModel.authorsAsString ?? viewModel.feed?.feedURL?.host() ?? "")
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        Text(viewModel.date ?? .now, style: .offset)
          .font(.scaledFootnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.bottom, .statusComponentSpacing)
  }

  private func bodyView() -> some View {
    VStack(alignment: .leading, spacing: .statusComponentSpacing) {
      if
        let previewImageURL = viewModel.previewImageURL
      {
        let width = viewModel.previewImageWidth
        let height = viewModel.previewImageHeight
        RSSPreviewImage(url: previewImageURL, originalSize: CGSize(width: width, height: height))
      }

      Text(viewModel.title ?? "no title")
        .font(.scaledHeadline)
        .lineLimit(2)
        .padding(.vertical, .statusComponentSpacing)

      Text(viewModel.summary ?? "")
        .font(.scaledBody)
        .lineSpacing(CGFloat(theme.lineSpacing))
        .lineLimit(10)
    }
    .padding(.leading, contentPadding)
  }
}

