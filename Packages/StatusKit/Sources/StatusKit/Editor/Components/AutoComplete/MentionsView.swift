import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  struct MentionsView: View {
    @Environment(Theme.self) private var theme

    var viewModel: StatusEditor.ViewModel

    var body: some View {
      ForEach(viewModel.mentionsSuggestions) { account in
        Button {
          viewModel.selectMentionSuggestion(account: account)
        } label: {
          HStack {
            AvatarView(account.avatar, config: AvatarView.FrameConfig.badge)
            VStack(alignment: .leading) {
              EmojiTextApp(
                .init(stringValue: account.safeDisplayName),
                emojis: account.emojis
              )
              .emojiText.size(Font.scaledFootnoteFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
              .font(.scaledFootnote)
              .fontWeight(.bold)
              .foregroundColor(theme.labelColor)
              Text("@\(account.acct)")
                .font(.scaledFootnote)
                .foregroundStyle(theme.tintColor)
            }
          }
        }
      }
    }
  }
}
