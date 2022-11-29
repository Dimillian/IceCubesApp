import SwiftUI
import Models
import Routeur

struct StatusRowView: View {
  @EnvironmentObject private var routeurPath: RouterPath
  
  let status: Status

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Button {
          routeurPath.navigate(to: .accountDetail(id: status.account.id))
        } label: {
          accountView
        }.buttonStyle(.plain)

        Spacer()
        Text(status.createdAtFormatted)
          .font(.footnote)
          .foregroundColor(.gray)
      }
      NavigationLink(value: RouteurDestinations.statusDetail(id: status.id)) {
        Text(try! AttributedString(markdown: status.contentAsMarkdown))
      }
    }
  }
  
  @ViewBuilder
  private var accountView: some View {
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
  }
}
