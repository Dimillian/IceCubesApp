import DesignSystem
import Models
import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct StatusRowCardView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool

  @EnvironmentObject private var theme: Theme
  
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
    if let title = card.title, let url = URL(string: card.url) {
      VStack(alignment: .leading) {
        if let imageURL = card.image, !isInCaptureMode {
          GeometryReader { proxy in
            let width = imageWidthFor(proxy: proxy)
            let processors: [ImageProcessing] = [.resize(size: .init(width: width, height: imageHeight))]
            LazyImage(url: imageURL) { state in
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
            .processors(processors)
          }
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
        }.padding(8)
      }
      .frame(maxWidth: maxWidth)
      .fixedSize(horizontal: false, vertical: true)
      .background(theme.secondaryBackgroundColor)
      .cornerRadius(16)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(.gray.opacity(0.35), lineWidth: 1)
      )
      .onTapGesture {
        openURL(url)
      }
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
    }
  }
}
