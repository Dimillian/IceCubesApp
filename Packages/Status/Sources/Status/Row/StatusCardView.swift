import DesignSystem
import Models
import NukeUI
import Shimmer
import SwiftUI

public struct StatusCardView: View {
  @EnvironmentObject private var theme: Theme
  @Environment(\.openURL) private var openURL
  let card: Card

  public init(card: Card) {
    self.card = card
  }

  public var body: some View {
    if let title = card.title, let url = URL(string: card.url) {
      VStack(alignment: .leading) {
        if let imageURL = card.image {
          LazyImage(url: imageURL) { state in
            if let image = state.image {
              image
                .resizingMode(.aspectFill)
            } else if state.isLoading {
              Rectangle()
                .fill(Color.gray)
                .frame(height: 200)
                .shimmering()
            }
          }
          .frame(height: 200)
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
          Label("Share this link", systemImage: "square.and.arrow.up")
        }
        Button { openURL(url) } label: {
          Label("status.action.view-in-browser", systemImage: "safari")
        }
        Divider()
        Button {
          UIPasteboard.general.url = url
        } label: {
          Label("Copy link", systemImage: "doc.on.doc")
        }
      }
    }
  }
}
