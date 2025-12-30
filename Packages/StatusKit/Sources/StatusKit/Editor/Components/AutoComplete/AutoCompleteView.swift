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

    var store: EditorStore

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
      if !store.mentionsSuggestions.isEmpty ||
          !store.tagsSuggestions.isEmpty ||
          store.showRecentsTagsInline
      {
        VStack {
          HStack {
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack {
                if !store.mentionsSuggestions.isEmpty {
                  Self.MentionsView(store: store)
                } else {
                  if #available(iOS 26, *), Assistant.isAvailable, store.tagsSuggestions.isEmpty {
                    Self.SuggestedTagsView(store: store,
                                           isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  } else if store.showRecentsTagsInline {
                    Self.RecentTagsView(
                      store: store, isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  } else {
                    Self.RemoteTagsView(
                      store: store, isTagSuggestionExpanded: $isTagSuggestionExpanded)
                  }
                }
              }
              .padding(.horizontal, .layoutPadding)
            }
            .scrollContentBackground(.hidden)
            if store.mentionsSuggestions.isEmpty {
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
              store: store, isTagSuggestionExpanded: $isTagSuggestionExpanded)
          }
        }
      }
    }
  }
}
