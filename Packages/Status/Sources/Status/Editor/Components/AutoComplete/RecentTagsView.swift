import DesignSystem
import EmojiText
import Foundation
import SwiftUI
import Models
import SwiftData


extension StatusEditorAutoCompleteView {
  struct RecentTagsView: View {
    @Environment(Theme.self) private var theme
    
    var viewModel: StatusEditorViewModel
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
          }
        }
      }
    }
  }
}
