import DesignSystem
import Env
import SwiftUI

@MainActor
public struct TimelineContentFilterView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(RouterPath.self) private var routerPath

  @State private var contentFilter = TimelineContentFilter.shared
  @State private var isEditingFilters = false

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          Toggle(isOn: $contentFilter.showBoosts) {
            Label("timeline.filter.show-boosts", systemImage: "arrow.2.squarepath")
          }
          Toggle(isOn: $contentFilter.showReplies) {
            Label("timeline.filter.show-replies", systemImage: "bubble.left.and.bubble.right")
          }
          Toggle(isOn: $contentFilter.showThreads) {
            Label("timeline.filter.show-threads", systemImage: "bubble.left.and.text.bubble.right")
          }
          Toggle(isOn: $contentFilter.showQuotePosts) {
            Label("timeline.filter.show-quote", systemImage: "quote.bubble")
          }
        }

        Section {
          if currentInstance.isFiltersSupported {
            Button {
              routerPath.presentedSheet = .accountFiltersList
            } label: {
              Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
      }
      .navigationTitle("timeline.content-filter.title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text("action.done").bold()
          }
        }
      }
    }
    .presentationDetents([.medium])
  }
}
