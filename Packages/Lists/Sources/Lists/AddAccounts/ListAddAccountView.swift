import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct ListAddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var viewModel: ListAddAccountViewModel
  @State private var isPresentingCreateList = false

  public init(account: Account) {
    _viewModel = .init(initialValue: .init(account: account))
  }

  public var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            isPresentingCreateList = true
          } label: {
            Label("account.list.create", systemImage: "plus")
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)

        ForEach(currentAccount.sortedLists) { list in
          HStack {
            Toggle(
              list.title,
              isOn: .init(
                get: {
                  viewModel.inLists.contains(where: { $0.id == list.id })
                },
                set: { value in
                  Task {
                    if value {
                      await viewModel.addToList(list: list)
                    } else {
                      await viewModel.removeFromList(list: list)
                    }
                  }
                })
            )
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
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("action.done") {
            dismiss()
          }
        }
      }
    }
    .sheet(isPresented: $isPresentingCreateList) {
      ListCreateView()
    }
    .task {
      viewModel.client = client
      await viewModel.fetchInfo()
    }
  }
}
