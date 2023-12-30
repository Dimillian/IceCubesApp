import SwiftUI
import Models
import DesignSystem
import Env

struct TimelineTagHeaderView: View {
  @Environment(CurrentAccount.self) private var account
  
  @Binding var tag: Tag?
  
  var body: some View {
    if let tag {
      TimelineHeaderView {
        HStack {
          TagChartView(tag: tag)
            .padding(.top, 12)

          VStack(alignment: .leading, spacing: 4) {
            Text("#\(tag.name)")
              .font(.scaledHeadline)
            Text("timeline.n-recent-from-n-participants \(tag.totalUses) \(tag.totalAccounts)")
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
          }
          .accessibilityElement(children: .combine)
          Spacer()
          Button {
            Task {
              if tag.following {
                self.tag = await account.unfollowTag(id: tag.name)
              } else {
                self.tag = await account.followTag(id: tag.name)
              }
            }
          } label: {
            Text(tag.following ? "account.follow.following" : "account.follow.follow")
          }.buttonStyle(.bordered)
        }
      }
    }
  }
}
