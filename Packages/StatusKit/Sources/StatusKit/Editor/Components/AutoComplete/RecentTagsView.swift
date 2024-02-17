import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  struct RecentTagsView: View {
    @Environment(Theme.self) private var theme

    var viewModel: StatusEditor.ViewModel
    @Binding var isTagSuggestionExpanded: Bool

    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      ForEach(recentTags) { tag in
        Button {
          withAnimation {
            isTagSuggestionExpanded = false
            viewModel.selectHashtagSuggestion(tag: tag.title)
          }
          tag.lastUse = Date()
        } label: {
          VStack(alignment: .leading) {
            Text("#\(tag.title)")
              .font(.scaledFootnote)
              .fontWeight(.bold)
              .foregroundColor(theme.labelColor)
            Text(tag.formattedDate)
              .font(.scaledFootnote)
              .foregroundStyle(theme.tintColor)
          }
        }
      }
    }
  }
}
