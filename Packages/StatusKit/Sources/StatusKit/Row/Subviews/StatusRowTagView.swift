import DesignSystem
import Env
import SwiftUI

struct StatusRowTagView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme

  @Environment(\.isHomeTimeline) private var isHomeTimeline

  let viewModel: StatusRowViewModel

  var body: some View {
    if isHomeTimeline, let tag = viewModel.userFollowedTag {
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
