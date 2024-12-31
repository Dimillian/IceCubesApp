import DesignSystem
import EmojiText
import Env
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  @MainActor
  struct ExpandedView: View {
    @Environment(\.modelContext) private var context
    @Environment(Theme.self) private var theme
    @Environment(CurrentAccount.self) private var currentAccount

    var viewModel: StatusEditor.ViewModel
    @Binding var isTagSuggestionExpanded: Bool

    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      TabView {
        recentTagsPage
        followedTagsPage
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .frame(height: 200)
    }

    private var recentTagsPage: some View {
      ScrollView(.vertical) {
        LazyVStack(alignment: .leading, spacing: 12) {
          Text("status.editor.language-select.recently-used")
            .font(.scaledSubheadline)
            .foregroundStyle(theme.labelColor)
            .fontWeight(.bold)
          ForEach(recentTags) { tag in
            HStack {
              Button {
                tag.lastUse = Date()
                withAnimation {
                  isTagSuggestionExpanded = false
                  viewModel.selectHashtagSuggestion(tag: tag.title)
                }
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
              Spacer()
            }
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
    }

    private var followedTagsPage: some View {
      ScrollView(.vertical) {
        LazyVStack(alignment: .leading, spacing: 12) {
          Text("timeline.filter.tags")
            .font(.scaledSubheadline)
            .foregroundStyle(theme.labelColor)
            .fontWeight(.bold)
          ForEach(currentAccount.tags) { tag in
            HStack {
              Button {
                if let index = recentTags.firstIndex(where: {
                  $0.title.lowercased() == tag.name.lowercased()
                }) {
                  recentTags[index].lastUse = Date()
                } else {
                  context.insert(RecentTag(title: tag.name))
                }
                withAnimation {
                  isTagSuggestionExpanded = false
                  viewModel.selectHashtagSuggestion(tag: tag.name)
                }
              } label: {
                VStack(alignment: .leading) {
                  Text("#\(tag.name)")
                    .font(.scaledFootnote)
                    .fontWeight(.bold)
                    .foregroundColor(theme.labelColor)
                }
              }
              Spacer()
            }
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
    }
  }
}
