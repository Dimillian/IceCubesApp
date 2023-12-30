import DesignSystem
import Models
import Nuke
import NukeUI
import Shimmer
import SwiftUI

@MainActor
public struct StatusRowCardView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool

  @Environment(Theme.self) private var theme

  let card: Card

  public init(card: Card) {
    self.card = card
  }

  private var maxWidth: CGFloat? {
    if theme.statusDisplayStyle == .medium {
      return 300
    }
    return nil
  }

  private func imageWidthFor(proxy: GeometryProxy) -> CGFloat {
    if theme.statusDisplayStyle == .medium, let maxWidth {
      return maxWidth
    }
    return proxy.frame(in: .local).width
  }

  private var imageHeight: CGFloat {
    if theme.statusDisplayStyle == .medium {
      return 100
    }
    return 200
  }

  public var body: some View {
    Button {
      if let url = URL(string: card.url) {
        openURL(url)
      }
    } label: {
      if let title = card.title, let url = URL(string: card.url) {
        VStack(alignment: .leading) {
          let sitesWithIcons = ["apps.apple.com", "music.apple.com", "open.spotify.com"]
          if let host = url.host(), sitesWithIcons.contains(host) {
            iconLinkPreview(title, url)
          } else {
            defaultLinkPreview(title, url)
          }
        }
        .frame(maxWidth: maxWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(.gray.opacity(0.35), lineWidth: 1)
        )
        .contextMenu {
          ShareLink(item: url) {
            Label("status.card.share", systemImage: "square.and.arrow.up")
          }
          Button { openURL(url) } label: {
            Label("status.action.view-in-browser", systemImage: "safari")
          }
          Divider()
          Button {
            UIPasteboard.general.url = url
          } label: {
            Label("status.card.copy", systemImage: "doc.on.doc")
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
        .accessibilityRemoveTraits(.isStaticText)
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func defaultLinkPreview(_ title: String, _ url: URL) -> some View {
    if let imageURL = card.image, !isInCaptureMode {
      LazyResizableImage(url: imageURL) { state, proxy in
        let width = imageWidthFor(proxy: proxy)
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: imageHeight)
            .frame(maxWidth: width)
            .clipped()
        } else if state.isLoading {
          Rectangle()
            .fill(Color.gray)
            .frame(height: imageHeight)
        }
      }
      // This image is decorative
      .accessibilityHidden(true)
      .frame(height: imageHeight)
    }
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(.scaledHeadline)
          .lineLimit(3)
        if let description = card.description, !description.isEmpty {
          Text(description)
            .font(.scaledBody)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        Text(url.host() ?? url.absoluteString)
          .font(.scaledFootnote)
          .foregroundColor(theme.tintColor)
          .lineLimit(1)
      }
      Spacer()
    }.padding(16)
  }

  private func iconLinkPreview(_ title: String, _ url: URL) -> some View {
    // ..where the image is known to be a square icon
    HStack {
      if let imageURL = card.image, !isInCaptureMode {
        LazyResizableImage(url: imageURL) { state, _ in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: imageHeight, height: imageHeight)
              .clipped()
          } else if state.isLoading {
            Rectangle()
              .fill(Color.gray)
              .frame(width: imageHeight, height: imageHeight)
          }
        }
        // This image is decorative
        .accessibilityHidden(true)
        .frame(width: imageHeight, height: imageHeight)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(.scaledHeadline)
          .lineLimit(3)
        if let description = card.description, !description.isEmpty {
          Text(description)
            .font(.scaledBody)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        Text(url.host() ?? url.absoluteString)
          .font(.scaledFootnote)
          .foregroundColor(theme.tintColor)
          .lineLimit(1)
      }.padding(16)
    }
  }
}
