import SwiftUI
import Network

struct StatusRowView: View {
  let status: Status

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        AsyncImage(
          url: status.account.avatar,
          content: { image in
            image.resizable()
              .aspectRatio(contentMode: .fit)
              .cornerRadius(13)
              .frame(maxWidth: 26, maxHeight: 26)
          },
          placeholder: {
            ProgressView()
          }
        )
        Text(status.account.username)
      }
      Text(status.content)
    }
  }
}
