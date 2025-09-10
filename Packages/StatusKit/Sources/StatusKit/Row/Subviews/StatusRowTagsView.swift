import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowTagsView: View {
  let tags: [Tag]

  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(tags) { tag in
          Button {
            routerPath.navigate(to: .hashTag(tag: tag.name, account: nil))
          } label: {
            Text("#\(tag.name)")
              .font(.footnote)
              .fontWeight(.medium)
              .lineLimit(1)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      }
    }
    .scrollClipDisabled()
  }
}
