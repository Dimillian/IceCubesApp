//
//  SwiftUIView.swift
//
//
//  Created by Duong Thai on 03/03/2024.
//

import SwiftUI
import StatusKit
import DesignSystem

@MainActor
public struct RSSItemView: View {
  @Environment(Theme.self) private var theme
  private let viewModel: RSSItem

  private var contentPadding: CGFloat {
    theme.avatarPosition == .top
    ? 0
    : AvatarView.FrameConfig.status.width + .statusColumnsSpacing
  }

  public init(_ viewModel: RSSItem) {
    self.viewModel = viewModel
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: .statusComponentSpacing) {
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

        /*
         Copy Link ???
         Copy Text ???
         Post this
         */
        if let url = viewModel.url {
          ShareLink(
            item: url,
            subject: Text(viewModel.title ?? ""),
            message: Text(viewModel.summary ?? "")
          )
          .buttonStyle(.borderless)
          .foregroundColor(Color(UIColor.secondaryLabel))
          .padding(.vertical, .statusComponentSpacing)
          //        .padding(.horizontal, 8)
          .contentShape(Rectangle())
#if targetEnvironment(macCatalyst)
          .font(.scaledBody)
#else
          .font(.body)
          .dynamicTypeSize(.large)
#endif
        }
      }
      .padding(.leading, contentPadding)
    }
  }
}

// FIXME: example data
//#Preview {
//  Theme.shared.avatarShape = .circle
//  Theme.shared.tintColor = .purple
//  Theme.shared.avatarPosition = .top
//
//  return RSSItemView(RSSExampleData.itemViewModel)
//    .frame(width: 430)
//    .environment(Theme.shared)
//}
