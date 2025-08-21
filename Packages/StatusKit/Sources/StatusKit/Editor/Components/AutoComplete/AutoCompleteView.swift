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
      if #available(iOS 26, *) {
        contentView
          .padding(.vertical, 8)
          .glassEffect(
            .regular.tint(theme.primaryBackgroundColor.opacity(0.2)),
            in: RoundedRectangle(cornerRadius: 8)
          )
          .padding(.horizontal, 16)
      } else {
        contentView
          .background(.thinMaterial)
      }
    }

    @ViewBuilder
    var contentView: some View {
      if !viewModel.mentionsSuggestions.isEmpty ||
          !viewModel.tagsSuggestions.isEmpty ||
          viewModel.showRecentsTagsInline
      {
        VStack {
          HStack {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack {
                if !viewModel.mentionsSuggestions.isEmpty {
                  Self.MentionsView(viewModel: viewModel)
                } else {
                  if #available(iOS 26, *), Assistant.isAvailable, viewModel.tagsSuggestions.isEmpty {
                    Self.SuggestedTagsView(viewModel: viewModel,
                                           isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  } else if viewModel.showRecentsTagsInline {
                    Self.RecentTagsView(
                      viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  } else {
                    Self.RemoteTagsView(
                      viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
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
                Image(
                  systemName: isTagSuggestionExpanded ? "chevron.down.circle" : "chevron.up.circle"
                )
                .padding(.trailing, 8)
              }
            }
          }
          .frame(height: 40)
          if isTagSuggestionExpanded {
            Self.ExpandedView(
              viewModel: viewModel, isTagSuggestionExpanded: $isTagSuggestionExpanded)
          }
        }
      }
    }
  }
}
