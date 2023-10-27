import DesignSystem
import Models
import Nuke
import NukeUI
import Shimmer
import SwiftUI

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
                  .foregroundColor(.gray)
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
}


struct LazyResizableImage<Content: View>: View {
    init(url: URL?, @ViewBuilder content: @escaping (LazyImageState, GeometryProxy) -> Content) {
        self.imageURL = url
        self.content = content
    }

    let imageURL: URL?
    @State private var resizeProcessor: ImageProcessors.Resize?
    @State private var debouncedTask: Task<Void, Never>?

    @ViewBuilder
    private var content: (LazyImageState, _ proxy: GeometryProxy) -> Content

    var body: some View {
        GeometryReader { proxy in
            LazyImage(url: imageURL) { state in
                content(state, proxy)
            }
            .processors([resizeProcessor == nil ? .resize(size: proxy.size) : resizeProcessor!])
            .onChange(of: proxy.size, initial: true) { oldValue, newValue in
                debouncedTask?.cancel()
                debouncedTask = Task {
                    do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                    resizeProcessor = .resize(size: newValue)
                }
            }
        }
    }
}
