import SwiftUI
import Models
import Shimmer
import Nuke
import NukeUI

public struct StatusCardView: View {
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
        Spacer()
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
      .background(Color.gray.opacity(0.15))
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
