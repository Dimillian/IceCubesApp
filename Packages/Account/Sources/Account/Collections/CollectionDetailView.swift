import DesignSystem
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct CollectionDetailView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  public let collection: AccountCollection

  @State private var fetchedCollection: AccountCollection?
  @State private var accounts: [Account] = []
  @State private var isLoading: Bool = true
  @State private var didError: Bool = false
  @State private var isSensitiveContentRevealed: Bool = false

  public init(collection: AccountCollection) {
    self.collection = collection
  }

  public var body: some View {
    List {
      if isSensitiveContentHidden {
        sensitiveContentSection
      } else {
        headerSection
        accountsSection
      }
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle(displayedCollection.name)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: isSensitiveContentRevealed) {
      guard !isSensitiveContentHidden else { return }
      await fetchAccounts()
    }
  }

  private var displayedCollection: AccountCollection {
    fetchedCollection ?? collection
  }

  private var isSensitiveContentHidden: Bool {
    displayedCollection.sensitive && !isSensitiveContentRevealed
  }

  private var sensitiveContentSection: some View {
    Section {
      Button {
        isSensitiveContentRevealed = true
      } label: {
        Label("status.media.sensitive.show", systemImage: "eye")
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var headerSection: some View {
    Section {
      if !displayedCollection.description.asRawText.isEmpty {
        Text(displayedCollection.description.asSafeMarkdownAttributedString)
          .font(.scaledBody)
      }
      if let tag = displayedCollection.tag {
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
      fetchedCollection = response.collection
      let acceptedAccountIds = Set(response.collection.acceptedAccountIds)
      accounts = response.accounts.filter { acceptedAccountIds.contains($0.id) }
      isLoading = false
    } catch {
      isLoading = false
      didError = true
    }
  }
}
