import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  struct RemoteTagsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Theme.self) private var theme

    var viewModel: StatusEditor.ViewModel
    @Binding var isTagSuggestionExpanded: Bool

    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      ForEach(viewModel.tagsSuggestions) { tag in
        Button {
          withAnimation {
            isTagSuggestionExpanded = false
            viewModel.selectHashtagSuggestion(tag: tag.name)
          }
          if let index = recentTags.firstIndex(where: {
            $0.title.lowercased() == tag.name.lowercased()
          }) {
            recentTags[index].lastUse = Date()
          } else {
            context.insert(RecentTag(title: tag.name))
          }
        } label: {
          VStack(alignment: .leading) {
            Text("#\(tag.name)")
              .font(.scaledFootnote)
              .fontWeight(.bold)
              .foregroundColor(theme.labelColor)
            Text("tag.suggested.mentions-\(tag.totalUses)")
              .font(.scaledFootnote)
              .foregroundStyle(theme.tintColor)
          }
        }
      }
    }
  }
}
