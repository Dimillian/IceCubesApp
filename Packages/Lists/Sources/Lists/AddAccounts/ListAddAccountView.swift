import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct ListAddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var viewModel: ListAddAccountViewModel

  public init(account: Account) {
    _viewModel = .init(initialValue: .init(account: account))
  }

  public var body: some View {
    NavigationStack {
      List {
        ForEach(currentAccount.sortedLists) { list in
          HStack {
            Toggle(list.title, isOn: .init(get: {
              viewModel.inLists.contains(where: { $0.id == list.id })
            }, set: { value in
              Task {
                if value {
                  await viewModel.addToList(list: list)
                } else {
                  await viewModel.removeFromList(list: list)
                }
              }
            }))
            .disabled(viewModel.isLoadingInfo)
            Spacer()
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("lists.add-remove-\(viewModel.account.safeDisplayName)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem {
          Button("action.done") {
            dismiss()
          }
        }
      }
    }
    .task {
      viewModel.client = client
      await viewModel.fetchInfo()
    }
  }
}
