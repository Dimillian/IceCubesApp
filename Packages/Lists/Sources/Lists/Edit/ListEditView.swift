import SwiftUI
import Models
import DesignSystem
import Network
import EmojiText

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
        Section("Users in this list") {
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
                  EmojiTextApp(account.safeDisplayName.asMarkdown,
                               emojis: account.emojis)
                  Text("@\(account.acct)")
                    .foregroundColor(.gray)
                    .font(.footnote)
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
          Button("Done") {
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
