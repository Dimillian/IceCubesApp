import Env
import Models
import SwiftUI

public struct TagRowView: View {
  @EnvironmentObject private var routerPath: RouterPath

  let tag: Tag

  public init(tag: Tag) {
    self.tag = tag
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("#\(tag.name)")
          .font(.scaledHeadline)
        Text("design.tag.n-posts-from-n-participants \(tag.totalUses) \(tag.totalAccounts)")
          .font(.scaledFootnote)
          .foregroundColor(.gray)
      }
      Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routerPath.navigate(to: .hashTag(tag: tag.name, account: nil))
    }
  }
}
