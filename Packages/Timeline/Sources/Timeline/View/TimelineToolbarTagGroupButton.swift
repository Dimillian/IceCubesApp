import DesignSystem
import Models
import SwiftData
import SwiftUI

struct TimelineToolbarTagGroupButton: ToolbarContent {
  @Environment(Theme.self) private var theme
  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  @Binding var timeline: TimelineFilter

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      switch timeline {
      case .hashtag(let tag, _):
        if !tagGroups.isEmpty {
          Menu {
            Section("tag-groups.edit.section.title") {
              ForEach(tagGroups) { group in
                Button {
                  if group.tags.contains(tag) {
                    group.tags.removeAll(where: { $0 == tag })
                  } else {
                    group.tags.append(tag)
                  }
                } label: {
                  Label(
                    group.title,
                    systemImage: group.tags.contains(tag)
                      ? "checkmark.rectangle.fill" : "checkmark.rectangle")
                }
              }
            }
          } label: {
            Image(systemName: "ellipsis")
              .foregroundStyle(theme.labelColor)
          }
        }
      default:
        EmptyView()
      }
    }
  }
}
