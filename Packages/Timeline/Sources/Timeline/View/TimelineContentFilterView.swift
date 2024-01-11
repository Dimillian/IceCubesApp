import SwiftUI
import DesignSystem

public struct TimelineContentFilterView: View {
  @Environment(Theme.self) private var theme
  
  @State private var contentFilter = TimelineContentFilter.shared
    
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
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("timeline.content-filter.title")
    .navigationBarTitleDisplayMode(.inline)
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    #endif
  }
}
