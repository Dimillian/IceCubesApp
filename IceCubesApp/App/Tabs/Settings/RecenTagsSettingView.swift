import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI

struct RecenTagsSettingView: View {
  @Environment(\.modelContext) private var context

  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme

  @Query(sort: \RecentTag.lastUse, order: .reverse) var tags: [RecentTag]

  var body: some View {
    Form {
      ForEach(tags) { tag in
        VStack(alignment: .leading) {
          Text("#\(tag.title)")
            .font(.scaledBody)
            .foregroundColor(.primary)
          Text(tag.formattedDate)
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
        }
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
