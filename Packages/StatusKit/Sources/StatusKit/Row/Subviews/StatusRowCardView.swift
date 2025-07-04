import DesignSystem
import Env
import Models
import Nuke
import NukeUI
import SwiftUI

@MainActor
public struct StatusRowCardView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.isCompact) private var isCompact: Bool

  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentInstance.self) private var currentInstance

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
    if theme.statusDisplayStyle == .medium || isCompact {
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
        VStack(alignment: .leading, spacing: 0) {
          let sitesWithIcons = [
            "apps.apple.com", "music.apple.com", "podcasts.apple.com", "open.spotify.com",
          ]
          if isCompact {
            compactLinkPreview(title, url)
          } else if UIDevice.current.userInterfaceIdiom == .pad
            || UIDevice.current.userInterfaceIdiom == .mac
            || UIDevice.current.userInterfaceIdiom == .vision,
            let host = url.host(), sitesWithIcons.contains(host)
          {
            iconLinkPreview(title, url)
          } else {
            defaultLinkPreview(title, url)
          }
        }
        .frame(maxWidth: maxWidth)
        .fixedSize(horizontal: false, vertical: true)
        #if os(visionOS)
          .if(
            !isCompact,
            transform: { view in
              view.background(.background)
            }
          )
          .hoverEffect()
        #else
          .background(isCompact ? .clear : theme.secondaryBackgroundColor)
        #endif
        .cornerRadius(isCompact ? 0 : 10)
        .overlay {
          if !isCompact {
            RoundedRectangle(cornerRadius: 10)
              .stroke(.gray.opacity(0.35), lineWidth: 1)
          }
        }
        .draggable(url)
        .contextMenu {
          ShareLink(item: url) {
            Label("status.card.share", systemImage: "square.and.arrow.up")
          }
          Button {
            openURL(url)
          } label: {
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
    if let imageURL = card.image {
      DefaultPreviewImage(
        url: imageURL, originalWidth: card.width ?? 0, originalHeight: card.height ?? 0)
    }

    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.scaledHeadline)
        .lineLimit(2)
      if let description = card.description, !description.isEmpty {
        Text(description)
          .font(.scaledFootnote)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
      Text(url.host() ?? url.absoluteString)
        .font(.scaledFootnote)
        .foregroundColor(theme.tintColor)
        .lineLimit(1)
      if let account = card.authors?.first?.account {
        moreFromAccountView(account)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
  }

  private func compactLinkPreview(_ title: String, _ url: URL) -> some View {
    HStack(alignment: .top) {
      if let imageURL = card.image {
        LazyResizableImage(url: imageURL) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: imageHeight, height: imageHeight)
              .clipShape(RoundedRectangle(cornerRadius: 8))
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
        Text(card.providerName ?? url.host() ?? url.absoluteString)
          .font(.scaledFootnote)
          .foregroundColor(theme.tintColor)
          .lineLimit(1)
        Text(title)
          .font(.scaledHeadline)
          .lineLimit(3)
        if let account = card.authors?.first?.account {
          moreFromAccountView(account, divider: false)
        } else if let authorName = card.authorName, !authorName.isEmpty {
          Text("by \(authorName)")
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        if let history = card.history {
          let uses = history.compactMap { Int($0.accounts) }.reduce(0, +)
          HStack(spacing: 4) {
            Button {
              if currentInstance.isLinkTimelineSupported {
                routerPath.navigate(to: .linkTimeline(url: url, title: title))
              }
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                Text("trending-tag-people-talking \(uses)")
                if currentInstance.isLinkTimelineSupported {
                  Image(systemName: "chevron.right")
                }
              }
            }
            .buttonStyle(.bordered)

            Spacer()
            Button {
              #if targetEnvironment(macCatalyst)
                openWindow(value: WindowDestinationEditor.quoteLinkStatusEditor(link: url))
              #else
                routerPath.presentedSheet = .quoteLinkStatusEditor(link: url)
              #endif
            } label: {
              Image(systemName: "quote.opening")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
          }
          .font(.scaledCaption)
          .lineLimit(1)
          .padding(.top, 12)
        }
      }
      .padding(.horizontal, 8)
    }
  }

  private func iconLinkPreview(_ title: String, _ url: URL) -> some View {
    // ..where the image is known to be a square icon
    HStack {
      if let imageURL = card.image {
        LazyResizableImage(url: imageURL) { state in
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

  @ViewBuilder
  private func moreFromAccountView(_ account: Account, divider: Bool = true) -> some View {
    if divider {
      Divider()
    }
    Button {
      routerPath.navigate(to: .accountDetailWithAccount(account: account))
    } label: {
      HStack(alignment: .center, spacing: 4) {
        Image(systemName: "link")
        Text("More from")
        AvatarView(account.avatar, config: .boost)
          .padding(.top, 2)
        EmojiTextApp(account.cachedDisplayName, emojis: account.emojis, lineLimit: 1)
          .fontWeight(.semibold)
          .emojiText.size(Font.scaledFootnoteFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
        Spacer()
        Image(systemName: "chevron.right")
      }
      .font(.scaledFootnote)
      .lineLimit(1)
      .padding(.top, 4)
    }
    .buttonStyle(.plain)
  }
}

struct DefaultPreviewImage: View {
  @Environment(Theme.self) private var theme

  let url: URL
  let originalWidth: CGFloat
  let originalHeight: CGFloat

  var body: some View {
    _Layout(originalWidth: originalWidth, originalHeight: originalHeight) {
      LazyResizableImage(url: url) { state in
        if let image = state.image?.resizable() {
          Rectangle().fill(theme.secondaryBackgroundColor)
            .overlay { image.scaledToFill().blur(radius: 50) }
            .overlay { image.scaledToFit() }
        }
      }
      .accessibilityHidden(true)  // This image is decorative
      .clipped()
    }
  }

  private struct _Layout: Layout {
    let originalWidth: CGFloat
    let originalHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
      guard !subviews.isEmpty else { return CGSize.zero }
      return calculateSize(proposal)
    }

    func placeSubviews(
      in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()
    ) {
      guard let view = subviews.first else { return }

      let size = calculateSize(proposal)
      view.place(at: bounds.origin, proposal: ProposedViewSize(size))
    }

    private func calculateSize(_ proposal: ProposedViewSize) -> CGSize {
      var size =
        switch (proposal.width, proposal.height) {
        case (nil, nil):
          CGSize(width: originalWidth, height: originalWidth)
        case let (nil, .some(height)):
          CGSize(width: originalWidth, height: min(height, originalWidth))
        case (0, _):
          CGSize.zero
        case let (.some(width), _):
          if originalWidth == 0 {
            CGSize(width: width, height: width / 2)
          } else {
            CGSize(width: width, height: width / originalWidth * originalHeight)
          }
        }

      size.height = min(size.height, 450)
      return size
    }
  }
}
