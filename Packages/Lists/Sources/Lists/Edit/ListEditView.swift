import DesignSystem
import EmojiText
import Models
import Network
import SwiftUI

public struct ListEditView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client

  @StateObject private var viewModel: ListEditViewModel

  public init(list: Models.List) {
    _viewModel = StateObject(wrappedValue: .init(list: list))
  }

  public var body: some View {
    NavigationStack {
      List {
        Section("lists.edit.users-in-list") {
          if viewModel.isLoadingAccounts {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
            .listRowBackground(theme.primaryBackgroundColor)
          } else {
            ForEach(viewModel.accounts) { account in
              HStack {
                AvatarView(url: account.avatar, size: .status)
                VStack(alignment: .leading) {
                  EmojiTextApp(.init(stringValue: account.safeDisplayName),
                               emojis: account.emojis)
                  Text("@\(account.acct)")
                    .foregroundColor(.gray)
                    .font(.scaledFootnote)
                }
              }
              .listRowBackground(theme.primaryBackgroundColor)
            }.onDelete { indexes in
              if let index = indexes.first {
                Task {
                  let account = viewModel.accounts[index]
                  await viewModel.delete(account: account)
                }
              }
            }
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .toolbar {
        ToolbarItem {
          Button("action.done") {
            dismiss()
          }
        }
      }
      .navigationTitle(viewModel.list.title)
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        viewModel.client = client
        Task {
          await viewModel.fetchAccounts()
        }
      }
    }
  }
}
