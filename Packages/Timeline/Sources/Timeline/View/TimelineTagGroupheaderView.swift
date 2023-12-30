import SwiftUI
import Models
import Env

struct TimelineTagGroupheaderView: View {
  @Environment(RouterPath.self) private var routerPath
  
  @Binding var group: TagGroup?
  @Binding var timeline: TimelineFilter
  
  var body: some View {
    if let group {
      TimelineHeaderView {
        HStack {
          ScrollView(.horizontal) {
            HStack(spacing: 4) {
              ForEach(group.tags, id: \.self) { tag in
                Button {
                  routerPath.navigate(to: .hashTag(tag: tag, account: nil))
                } label: {
                  Text("#\(tag)")
                    .font(.scaledHeadline)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .scrollIndicators(.hidden)
          Button("status.action.edit") {
            routerPath.presentedSheet = .editTagGroup(tagGroup: group, onSaved: { group in
              timeline = .tagGroup(title: group.title, tags: group.tags)
            })
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }
}
