import DesignSystem
import Env
import Models
import SwiftUI

public struct ListsListView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(Theme.self) private var theme

  public init() {}

  public var body: some View {
    List {
      ForEach(currentAccount.lists) { list in
        NavigationLink(value: RouterDestination.list(list: list)) {
          Text(list.title)
            .font(.scaledHeadline)
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }
      .onDelete { index in
        if let index = index.first {
          Task {
            await currentAccount.deleteList(currentAccount.lists[index])
          }
        }
      }
    }
    .task {
      await currentAccount.fetchLists()
    }
    .refreshable {
      await currentAccount.fetchLists()
    }
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    #endif
    .listStyle(.plain)
    .navigationTitle("timeline.filter.lists")
    .navigationBarTitleDisplayMode(.inline)
  }
}
