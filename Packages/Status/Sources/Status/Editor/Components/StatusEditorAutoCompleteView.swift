import Foundation
import SwiftUI
import DesignSystem

struct StatusEditorAutoCompleteView: View {
  @EnvironmentObject private var theme: Theme
  @ObservedObject var viewModel: StatusEditorViewModel
  
  var body: some View {
    if !viewModel.mentionsSuggestions.isEmpty || !viewModel.tagsSuggestions.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          if !viewModel.mentionsSuggestions.isEmpty {
            suggestionsMentionsView
          } else {
            suggestionsTagView
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
      .frame(height: 40)
      .background(.ultraThinMaterial)
    }
  }
  
  private var suggestionsMentionsView: some View {
    ForEach(viewModel.mentionsSuggestions) { account in
      Button {
        viewModel.selectMentionSuggestion(account: account)
      } label: {
        HStack {
          AvatarView(url: account.avatar, size: .badge)
          VStack(alignment: .leading) {
            Text(account.displayName)
              .font(.footnote)
              .foregroundColor(theme.labelColor)
            Text("@\(account.acct)")
              .font(.caption)
              .foregroundColor(theme.tintColor)
          }
        }
      }
    }
  }

  private var suggestionsTagView: some View {
    ForEach(viewModel.tagsSuggestions) { tag in
      Button {
        viewModel.selectHashtagSuggestion(tag: tag)
      } label: {
        Text("#\(tag.name)")
          .font(.caption)
          .foregroundColor(theme.tintColor)
      }
    }
  }

}
