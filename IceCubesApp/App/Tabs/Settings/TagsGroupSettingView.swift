import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI

struct TagsGroupSettingView: View {
  @Environment(\.modelContext) private var context

  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme

  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  var body: some View {
    Form {
      ForEach(tagGroups) { group in
        Button {
          routerPath.presentedSheet = .editTagGroup(tagGroup: group, onSaved: nil)
        } label: {
          Label(group.title, systemImage: group.symbolName)
        }
        .tint(.primary)
      }
      .onDelete { indexes in
        if let index = indexes.first {
          context.delete(tagGroups[index])
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Button {
        routerPath.presentedSheet = .addTagGroup
      } label: {
        Label("timeline.filter.add-tag-groups", systemImage: "plus")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("timeline.filter.tag-groups")
    .scrollContentBackground(.hidden)
    #if !os(visionOS)
      .background(theme.secondaryBackgroundColor)
    #endif
    .toolbar {
      EditButton()
    }
  }
}
