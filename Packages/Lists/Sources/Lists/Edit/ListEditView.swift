import Account
import DesignSystem
import EmojiText
import Models
import Network
import SwiftUI

@MainActor
public struct ListEditView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client

  @State private var viewModel: ListEditViewModel

  public init(list: Models.List) {
    _viewModel = .init(initialValue: .init(list: list))
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section("lists.edit.settings") {
          TextField("list.edit.title", text: $viewModel.title) {
            Task { await viewModel.update() }
          }
          Picker("list.edit.repliesPolicy",
                 selection: $viewModel.repliesPolicy)
          {
            ForEach(Models.List.RepliesPolicy.allCases) { policy in
              Text(policy.title)
                .tag(policy)
            }
          }
          Toggle("list.edit.isExclusive", isOn: $viewModel.isExclusive)
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .disabled(viewModel.isUpdating)
        .onChange(of: viewModel.repliesPolicy) { _, _ in
          Task { await viewModel.update() }
        }
        .onChange(of: viewModel.isExclusive) { _, _ in
          Task { await viewModel.update() }
        }

        Section("lists.edit.users-in-list") {
          HStack {
            TextField("lists.edit.users-search",
                      text: $viewModel.searchUserQuery)
            if !viewModel.searchUserQuery.isEmpty {
              Button {
                viewModel.searchUserQuery = ""
              } label: {
                Image(systemName: "xmark.circle")
              }
            }
          }
          .id("stableId")
          if !viewModel.searchUserQuery.isEmpty {
            searchAccountsView
          } else {
            listAccountsView
          }
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .disabled(viewModel.isUpdating)
      }
      #if !os(visionOS)
      .scrollDismissesKeyboard(.immediately)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      #endif
      .toolbar {
        ToolbarItem {
          Button {
            Task {
              await viewModel.update()
              dismiss()
            }
          } label: {
            if viewModel.isUpdating {
              ProgressView()
            } else {
              Text("action.done")
            }
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
      .task(id: viewModel.searchUserQuery) {
        do {
          viewModel.isSearching = true
          try await Task.sleep(for: .milliseconds(150))
          await viewModel.searchUsers()
        } catch {}
      }
    }
  }

  private var loadingView: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .id(UUID())
  }

  @ViewBuilder
  private var searchAccountsView: some View {
    if viewModel.isSearching {
      loadingView
    } else {
      ForEach(viewModel.searchedAccounts) { account in
        HStack {
          AvatarView(account.avatar)
          VStack(alignment: .leading) {
            EmojiTextApp(.init(stringValue: account.safeDisplayName),
                         emojis: account.emojis)
              .emojiText.size(Font.scaledBodyFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
            Text("@\(account.acct)")
              .foregroundStyle(.secondary)
              .font(.scaledFootnote)
              .lineLimit(1)
          }
          Spacer()
          if let relationship = viewModel.searchedRelationships[account.id] {
            if relationship.following {
              Toggle("", isOn: .init(get: {
                viewModel.accounts.contains(where: { $0.id == account.id })
              }, set: { addedToList in
                Task {
                  if addedToList {
                    await viewModel.add(account: account)
                  } else {
                    await viewModel.delete(account: account)
                  }
                }
              }))
            } else {
              FollowButton(viewModel: .init(accountId: account.id,
                                            relationship: relationship,
                                            shouldDisplayNotify: false,
                                            relationshipUpdated: { relationship in
                                              viewModel.searchedRelationships[account.id] = relationship
                                            }))
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private var listAccountsView: some View {
    if viewModel.isLoadingAccounts {
      loadingView
    } else {
      ForEach(viewModel.accounts) { account in
        HStack {
          AvatarView(account.avatar)
          VStack(alignment: .leading) {
            EmojiTextApp(.init(stringValue: account.safeDisplayName),
                         emojis: account.emojis)
              .emojiText.size(Font.scaledBodyFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
            Text("@\(account.acct)")
              .foregroundStyle(.secondary)
              .font(.scaledFootnote)
              .lineLimit(1)
          }
        }
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
