import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  @available(iOS 26.0, *)
  struct SuggestedTagsView: View {
    enum ViewState {
      case loading, loaded(tags: [String]), error
    }
    
    @Environment(\.modelContext) private var context
    @Environment(Theme.self) private var theme
    
    private let assistant = StatusEditor.Assistant()
    
    var viewModel: StatusEditor.ViewModel
    @Binding var isTagSuggestionExpanded: Bool
    
    @State var viewState: ViewState = .loading
    
    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      switch viewState {
      case .loading:
        ProgressView()
          .task {
            viewState = .loaded(tags: await assistant.generateTags(from: viewModel.statusText.string).values)
          }
      case .loaded(let tags):
        ForEach(tags, id: \.self ) { tag in
          Button {
            withAnimation {
              isTagSuggestionExpanded = false
              viewModel.selectHashtagSuggestion(tag: tag)
            }
            
            if let index = recentTags.firstIndex(where: {
              $0.title.lowercased() == tag.lowercased()
            }) {
              recentTags[index].lastUse = Date()
            } else {
              var tag = tag
              if tag.first == "#" {
                tag.removeFirst()
              }
              context.insert(RecentTag(title: tag))
            }
          } label: {
            Text(tag)
              .font(.scaledFootnote)
              .fontWeight(.bold)
              .foregroundColor(theme.labelColor)
          }
        }
      case .error:
        EmptyView()
      }
    }
  }
}
