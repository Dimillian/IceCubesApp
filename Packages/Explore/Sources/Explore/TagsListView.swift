import DesignSystem
import Models
import SwiftUI

public struct TagsListView: View {
  @Environment(Theme.self) private var theme

  let tags: [Tag]

  public init(tags: [Tag]) {
    self.tags = tags
  }

  public var body: some View {
    List {
      ForEach(tags) { tag in
        TagRowView(tag: tag)
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #endif
          .padding(.vertical, 4)
      }
    }
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .listStyle(.plain)
    #else
      .listStyle(.grouped)
    #endif
    .navigationTitle("explore.section.trending.tags")
    .navigationBarTitleDisplayMode(.inline)
  }
}
