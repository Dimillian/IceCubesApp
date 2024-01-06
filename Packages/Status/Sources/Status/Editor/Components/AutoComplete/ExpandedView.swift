import DesignSystem
import EmojiText
import Foundation
import SwiftUI
import Models
import SwiftData


extension StatusEditorAutoCompleteView {
  struct ExpandedView: View {
    @Environment(\.modelContext) private var context
    @Environment(Theme.self) private var theme
    
    var viewModel: StatusEditorViewModel
    @Binding var isTagSuggestionExpanded: Bool
    
    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]
    
    var body: some View {
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
      .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                          .onEnded({ value in
                            withAnimation {
                              if value.translation.height > 0 {
                                isTagSuggestionExpanded = false
                              }
                            }
                          }))
    }
  }
}
