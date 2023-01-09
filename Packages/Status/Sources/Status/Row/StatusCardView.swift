import SwiftUI
import Models
import Shimmer
import NukeUI
import DesignSystem

public struct StatusCardView: View {
  @EnvironmentObject private var theme: Theme
  @Environment(\.openURL) private var openURL
  let card: Card
  
  public init(card: Card) {
    self.card = card
  }
  
  public var body: some View {
    if let title = card.title {
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
              .font(.headline)
              .lineLimit(3)
            if let description = card.description, !description.isEmpty {
              Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            } else {
              Text(card.url.absoluteString)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            }
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
        openURL(card.url)
      }
    }
  }
}
