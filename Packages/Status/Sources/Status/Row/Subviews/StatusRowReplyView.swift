import DesignSystem
import SwiftUI

struct StatusRowReplyView: View {
  let viewModel: StatusRowViewModel

  var body: some View {
    Group {
      if let accountId = viewModel.status.inReplyToAccountId {
        if let mention = viewModel.status.mentions.first(where: { $0.id == accountId }) {
          HStack(spacing: 2) {
            Image(systemName: "arrowshape.turn.up.left.fill")
            Text("status.row.was-reply \(mention.username)")
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel(
            Text("status.row.was-reply \(mention.username)")
          )
          .onTapGesture {
            viewModel.navigateToMention(mention: mention)
          }
        } else if viewModel.isThread && accountId == viewModel.status.account.id {
          HStack(spacing: 2) {
            Image(systemName: "quote.opening")
            Text("status.row.is-thread")
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel(
            Text("status.row.is-thread")
          )
        }
      }
    }
    .font(.scaledFootnote)
    .foregroundColor(.gray)
    .fontWeight(.semibold)
  }
}
