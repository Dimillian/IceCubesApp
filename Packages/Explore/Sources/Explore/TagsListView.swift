import DesignSystem
import Models
import SwiftUI

public struct TagsListView: View {
  @EnvironmentObject private var theme: Theme

  let tags: [Tag]

  public init(tags: [Tag]) {
    self.tags = tags
  }

  public var body: some View {
    List {
      ForEach(tags) { tag in
        TagRowView(tag: tag)
          .listRowBackground(theme.primaryBackgroundColor)
          .padding(.vertical, 4)
      }
    }
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .listStyle(.plain)
    .navigationTitle("explore.section.trending.tags")
    .navigationBarTitleDisplayMode(.inline)
  }
}
