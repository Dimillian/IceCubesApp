import SwiftUI
import DesignSystem

struct StatusRowReplyView: View {
  let viewModel: StatusRowViewModel
  
  var body: some View {
    if let accountId = viewModel.status.inReplyToAccountId,
       let mention = viewModel.status.mentions.first(where: { $0.id == accountId })
    {
      HStack(spacing: 2) {
        Image(systemName: "arrowshape.turn.up.left.fill")
        Text("status.row.was-reply")
        Text(mention.username)
      }
      .font(.scaledFootnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        viewModel.navigateToMention(mention: mention)
      }
    }
  }
}
