import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor {
  @MainActor
  struct AutoCompleteView: View {
    @Environment(\.modelContext) var context

    @Environment(Theme.self) var theme

    var viewModel: ViewModel

    @State private var isTagSuggestionExpanded: Bool = false

    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      if !viewModel.mentionsSuggestions.isEmpty ||
        !viewModel.tagsSuggestions.isEmpty ||
        (viewModel.showRecentsTagsInline && !recentTags.isEmpty)
      {
        VStack {
          HStack {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack {
                if !viewModel.mentionsSuggestions.isEmpty {
                  Self.MentionsView(viewModel: viewModel)
                } else {
                  if viewModel.showRecentsTagsInline {
                    Self.RecentTagsView(viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  } else {
                    Self.RemoteTagsView(viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  }
                }
              }
              .padding(.horizontal, .layoutPadding)
            }
            .scrollContentBackground(.hidden)
            if viewModel.mentionsSuggestions.isEmpty {
              Spacer()
              Button {
                withAnimation {
                  isTagSuggestionExpanded.toggle()
                }
              } label: {
                Image(systemName: isTagSuggestionExpanded ? "chevron.down.circle" : "chevron.up.circle")
                  .padding(.trailing, 8)
              }
            }
          }
          .frame(height: 40)
          if isTagSuggestionExpanded {
            Self.ExpandedView(viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
          }
        }
        .background(.thinMaterial)
      }
    }
  }
}
