import DesignSystem
import EmojiText
import Foundation
import SwiftUI
import Models
import SwiftData

@MainActor
struct StatusEditorAutoCompleteView: View {
  @Environment(\.modelContext) private var context
  
  @Environment(Theme.self) private var theme
  
  var viewModel: StatusEditorViewModel
  
  @State private var isTagSuggestionExpanded: Bool = false
  
  @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

  var body: some View {
    if !viewModel.mentionsSuggestions.isEmpty || 
        !viewModel.tagsSuggestions.isEmpty ||
        (viewModel.showRecentsTagsInline && !recentTags.isEmpty)  {
      VStack {
        HStack {
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
          .scrollContentBackground(.hidden)
          if !viewModel.tagsSuggestions.isEmpty {
            Spacer()
            Button {
              withAnimation {
                isTagSuggestionExpanded.toggle()
              }
            } label: {
              Image(systemName: isTagSuggestionExpanded ? "chevron.down.circle" : "chevron.up.circle")
            }
            .padding(.trailing, 8)
          }
        }
        .frame(height: 40)
        if isTagSuggestionExpanded {
          expandedTagsSuggestionView
        }
      }
      .background(.thinMaterial)
    }
  }

  private var suggestionsMentionsView: some View {
    ForEach(viewModel.mentionsSuggestions) { account in
      Button {
        viewModel.selectMentionSuggestion(account: account)
      } label: {
        HStack {
          AvatarView(account.avatar, config: AvatarView.FrameConfig.badge)
          VStack(alignment: .leading) {
            EmojiTextApp(.init(stringValue: account.safeDisplayName),
                         emojis: account.emojis)
              .emojiSize(Font.scaledFootnoteFont.emojiSize)
              .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
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

  @ViewBuilder
  private var suggestionsTagView: some View {
    if viewModel.showRecentsTagsInline {
      recentTagsSuggestionView
    } else {
      remoteTagsSuggestionView
    }
  }
  
  private var recentTagsSuggestionView: some View {
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
  
  private var remoteTagsSuggestionView: some View {
    ForEach(viewModel.tagsSuggestions) { tag in
      Button {
        withAnimation {
          isTagSuggestionExpanded = false
          viewModel.selectHashtagSuggestion(tag: tag.name)
        }
        if let index = recentTags.firstIndex(where: { $0.title.lowercased() == tag.name.lowercased() }) {
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
  
  private var expandedTagsSuggestionView: some View {
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
              Text("#\(tag.title)")
                .font(.scaledFootnote)
                .fontWeight(.bold)
                .foregroundColor(theme.labelColor)
            }
            Spacer()
          }
        }
      }
      .padding(.horizontal, .layoutPadding)
    }
    .frame(height: 200)
  }
}
