import DesignSystem
import Env
import Models
import SwiftUI

public struct FollowedTagsListView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    List(currentAccount.tags) { tag in
      TagRowView(tag: tag)
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .padding(.vertical, 4)
    }
    .task {
      await currentAccount.fetchFollowedTags()
    }
    .refreshable {
      await currentAccount.fetchFollowedTags()
    }
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
    .listStyle(.plain)
    .navigationTitle("timeline.filter.tags")
    .navigationBarTitleDisplayMode(.inline)
  }
}
