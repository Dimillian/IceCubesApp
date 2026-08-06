import DesignSystem
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct CollectionDetailView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  public let collection: AccountCollection

  @State private var accounts: [Account] = []
  @State private var isLoading: Bool = true
  @State private var didError: Bool = false

  public init(collection: AccountCollection) {
    self.collection = collection
  }

  public var body: some View {
    List {
      headerSection
      accountsSection
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle(collection.name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await fetchAccounts()
    }
  }

  @ViewBuilder
  private var headerSection: some View {
    Section {
      if !collection.description.asRawText.isEmpty {
        Text(collection.description.asSafeMarkdownAttributedString)
          .font(.scaledBody)
      }
      if let tag = collection.tag {
        Text("#\(tag.name)")
          .font(.scaledCallout)
          .foregroundStyle(theme.tintColor)
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var accountsSection: some View {
    Section {
      if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, alignment: .center)
      } else if didError {
        Button("action.retry") {
          Task {
            await fetchAccounts()
          }
        }
        .frame(maxWidth: .infinity, alignment: .center)
      } else {
        ForEach(accounts) { account in
          AccountsListRow(viewModel: .init(account: account))
        }
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private func fetchAccounts() async {
    isLoading = true
    didError = false
    do {
      let response: AccountCollectionResponse = try await client.get(
        endpoint: Collections.collection(id: collection.id))
      accounts = response.accounts
      isLoading = false
    } catch {
      isLoading = false
      didError = true
    }
  }
}
