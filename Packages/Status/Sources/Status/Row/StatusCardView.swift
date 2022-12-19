import SwiftUI
import Models

struct StatusCardView: View {
  @Environment(\.openURL) private var openURL
  let status: AnyStatus
  
  var body: some View {
    if let card = status.card, let title = card.title {
      VStack(alignment: .leading) {
        if let imageURL = card.image {
          AsyncImage(
            url: imageURL,
            content: { image in
              image.resizable()
                .aspectRatio(contentMode: .fill)
            },
            placeholder: {
              ProgressView()
                .frame(maxWidth: 40, maxHeight: 40)
            }
          )
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

struct StatusCardView_Previews: PreviewProvider {
  static var previews: some View {
    StatusCardView(status: Status.placeholder())
  }
}
