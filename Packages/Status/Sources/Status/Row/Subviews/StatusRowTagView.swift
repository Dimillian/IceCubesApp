import DesignSystem
import SwiftUI
import Env

struct StatusRowTagView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  let viewModel: StatusRowViewModel

  var body: some View {
    if let tag = viewModel.finalStatus.content.links.first(where: { link in
      link.type == .hashtag && currentAccount.tags.contains(where: { $0.name.lowercased() == link.title.lowercased() })
    }) {
      Text("#\(tag.title)")
        .font(.scaledFootnote)
        .foregroundColor(.gray)
        .fontWeight(.semibold)
    }
  }
}
