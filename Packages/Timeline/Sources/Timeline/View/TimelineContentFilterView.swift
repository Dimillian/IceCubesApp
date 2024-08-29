import DesignSystem
import Env
import SwiftUI

@MainActor
public struct TimelineContentFilterView: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(RouterPath.self) private var routerPath

  @State private var contentFilter = TimelineContentFilter.shared
  @State private var isEditingFilters = false

  public init() {}

  public var body: some View {
    Form {
      Section {
        Toggle(isOn: $contentFilter.showBoosts) {
          Label("timeline.filter.show-boosts", image: "Rocket")
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
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor.opacity(0.3))
      #endif

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
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor.opacity(0.3))
      #endif
    }
    .navigationTitle("timeline.content-filter.title")
    .navigationBarTitleDisplayMode(.inline)
    .scrollContentBackground(.hidden)
  }
}
