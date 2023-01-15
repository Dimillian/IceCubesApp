import DesignSystem
import Env
import Models
import Network
import SwiftUI

public struct ListAddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var viewModel: ListAddAccountViewModel

  @State private var isCreateListAlertPresented: Bool = false
  @State private var createListTitle: String = ""

  public init(account: Account) {
    _viewModel = StateObject(wrappedValue: .init(account: account))
  }

  public var body: some View {
    NavigationStack {
      List {
        ForEach(currentAccount.lists) { list in
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
        Button("lists.create") {
          isCreateListAlertPresented = true
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("lists.add-remove-\(viewModel.account.displayName)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem {
          Button("action.done") {
            dismiss()
          }
        }
      }
      .alert("lists.create", isPresented: $isCreateListAlertPresented) {
        TextField("lists.name", text: $createListTitle)
        Button("action.cancel") {
          isCreateListAlertPresented = false
          createListTitle = ""
        }
        Button("lists.create.confirm") {
          guard !createListTitle.isEmpty else { return }
          isCreateListAlertPresented = false
          Task {
            await currentAccount.createList(title: createListTitle)
            createListTitle = ""
          }
        }
      } message: {
        Text("lists.name.message")
      }
    }
    .task {
      viewModel.client = client
      await viewModel.fetchInfo()
    }
  }
}
