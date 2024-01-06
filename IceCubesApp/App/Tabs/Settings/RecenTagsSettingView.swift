import SwiftUI
import SwiftData
import Models
import Env
import DesignSystem

struct RecenTagsSettingView: View {
  @Environment(\.modelContext) private var context
  
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  
  @Query(sort: \RecentTag.lastUse, order: .reverse) var tags: [RecentTag]
  
  var body: some View {
    Form {
      ForEach(tags) { tag in
        Text("#\(tag.title)")
      }.onDelete { indexes in
        if let index = indexes.first {
          context.delete(tags[index])
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.general.recent-tags")
    .scrollContentBackground(.hidden)
    #if !os(visionOS)
    .background(theme.secondaryBackgroundColor)
    #endif
    .toolbar {
      EditButton()
    }
  }
}
