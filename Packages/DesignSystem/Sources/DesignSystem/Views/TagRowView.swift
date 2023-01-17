import Env
import Models
import SwiftUI

public struct TagRowView: View {
  @EnvironmentObject private var routeurPath: RouterPath

  let tag: Tag

  public init(tag: Tag) {
    self.tag = tag
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("#\(tag.name)")
          .font(.headline)
        Text("\(tag.totalUses) posts from \(tag.totalAccounts) participants")
          .font(.footnote)
          .foregroundColor(.gray)
      }
      Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routeurPath.navigate(to: .hashTag(tag: tag.name, account: nil))
    }
  }
}
