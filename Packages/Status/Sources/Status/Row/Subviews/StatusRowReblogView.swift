import DesignSystem
import SwiftUI

struct StatusRowReblogView: View {
  let viewModel: StatusRowViewModel

  var body: some View {
    if viewModel.status.reblog != nil {
      HStack(spacing: 2) {
        Image("Rocket.Fill")
        AvatarView(account: viewModel.status.account, config: .boost, hasPopup: true)
        EmojiTextApp(.init(stringValue: viewModel.status.account.safeDisplayName), emojis: viewModel.status.account.emojis)
        Text("status.row.was-boosted")
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        Text("\(viewModel.status.account.safeDisplayName)")
          + Text(" ")
          + Text("status.row.was-boosted")
      )
      .font(.scaledFootnote)
      .emojiSize(Font.scaledFootnoteFont.emojiSize)
      .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        viewModel.navigateToAccountDetail(account: viewModel.status.account)
      }
    }
  }
}
