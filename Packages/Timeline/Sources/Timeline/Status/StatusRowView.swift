import SwiftUI
import Network

struct StatusRowView: View {
  let status: Status

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        AsyncImage(
          url: status.account.avatar,
          content: { image in
            image.resizable()
              .aspectRatio(contentMode: .fit)
              .cornerRadius(4)
              .frame(maxWidth: 40, maxHeight: 40)
          },
          placeholder: {
            ProgressView()
              .frame(maxWidth: 40, maxHeight: 40)
          }
        )
        VStack(alignment: .leading) {
          Text(status.account.displayName)
            .font(.headline)
          Text("@\(status.account.acct)")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        Spacer()
        Text(status.createdAtFormatted)
          .font(.footnote)
          .foregroundColor(.gray)
      }
      Text(try! AttributedString(markdown: status.contentAsMarkdown))
    }
  }
}
