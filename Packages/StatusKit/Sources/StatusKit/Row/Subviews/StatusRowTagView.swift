import DesignSystem
import Env
import SwiftUI

struct StatusRowTagView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(RouterPath.self) private var routerPath

  @Environment(\.isHomeTimeline) private var isHomeTimeline

  let viewModel: StatusRowViewModel

  var body: some View {
    if isHomeTimeline,
       let tag = viewModel.finalStatus.content.links.first(where: { link in
         link.type == .hashtag && currentAccount.tags.contains(where: { $0.name.lowercased() == link.title.lowercased() })
       })
    {
      Text("#\(tag.title)")
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
        .fontWeight(.semibold)
        .onTapGesture {
          routerPath.navigate(to: .hashTag(tag: tag.title, account: nil))
        }
    }
  }
}
