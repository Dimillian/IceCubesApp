import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct ConversationsListView: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(RouterPath.self) private var routerPath
  @Environment(StreamWatcher.self) private var watcher
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme

  @State private var dataSource = ConversationsListDataSource()
  @State private var viewState: ConversationsListState = .loading

  public init() {}

  public var body: some View {
    List {
      conversationsView
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle("conversations.navigation-title")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent {
        Task {
          await handleStreamEvent(latestEvent)
        }
      }
    }
    .refreshable {
      // note: this Task wrapper should not be necessary, but it reportedly crashes without it
      // when refreshing on an empty list
      Task {
        SoundEffectManager.shared.playSound(.pull)
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
        await fetchConversations()
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
        SoundEffectManager.shared.playSound(.refresh)
      }
    }
    .onAppear {
      if client.isAuth {
        Task {
          await fetchConversations()
        }
      }
    }
    .onChange(of: client) { oldValue, newValue in
      guard oldValue.id != newValue.id else { return }
      dataSource.reset()
      viewState = .loading
      Task {
        await fetchConversations()
      }
    }
  }

  @ViewBuilder
  private var conversationsView: some View {
    switch viewState {
    case .loading:
      ForEach(Conversation.placeholders()) { conversation in
        ConversationsListRow(
          conversation: .constant(conversation),
          onMarkAsRead: { _ in },
          onDelete: { _ in },
          onFavorite: { _ in },
          onBookmark: { _ in }
        )
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      }
      .listSectionSeparator(.hidden, edges: .top)
      .listRowBackground(theme.primaryBackgroundColor)

    case .display(let conversations, let hasNextPage):
      if conversations.isEmpty {
        PlaceholderView(
          iconName: "tray",
          title: "conversations.empty.title",
          message: "conversations.empty.message"
        )
      } else {
        ForEach(conversations) { conversation in
          ConversationsListRow(
            conversation: .constant(conversation),
            onMarkAsRead: markAsRead,
            onDelete: deleteConversation,
            onFavorite: toggleFavorite,
            onBookmark: toggleBookmark
          )
        }
        .listSectionSeparator(.hidden, edges: .top)
        .listRowBackground(theme.primaryBackgroundColor)

        if hasNextPage {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .listRowBackground(theme.primaryBackgroundColor)
          .onAppear {
            Task {
              await fetchNextPage()
            }
          }
        }
      }

    case .error:
      ErrorView(
        title: "conversations.error.title",
        message: "conversations.error.message",
        buttonTitle: "conversations.error.button"
      ) {
        await fetchConversations()
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
}

extension ConversationsListView {

  private func fetchConversations() async {
    do {
      let result = try await dataSource.fetchConversations(client: client)
      withAnimation {
        viewState = .display(conversations: result.conversations, hasNextPage: result.hasNextPage)
      }
    } catch {
      viewState = .error(error: error)
    }
  }

  private func fetchNextPage() async {
    do {
      let result = try await dataSource.fetchNextPage(client: client)
      viewState = .display(conversations: result.conversations, hasNextPage: result.hasNextPage)
    } catch {
      // Keep current state on pagination error
    }
  }

  private func handleStreamEvent(_ event: any StreamEvent) async {
    if let updatedConversations = dataSource.handleStreamEvent(event: event) {
      if case .display(_, let hasNextPage) = viewState {
        withAnimation {
          viewState = .display(conversations: updatedConversations, hasNextPage: hasNextPage)
        }
      }
    }
  }

  private func markAsRead(_ conversation: Conversation) async {
    let updatedConversation = await dataSource.markAsRead(
      client: client, conversation: conversation)
    updateConversation(updatedConversation)
  }

  private func deleteConversation(_ conversation: Conversation) async {
    do {
      let updatedConversations = try await dataSource.delete(
        client: client, conversation: conversation)
      if case .display(_, let hasNextPage) = viewState {
        withAnimation {
          viewState = .display(conversations: updatedConversations, hasNextPage: hasNextPage)
        }
      }
    } catch {
      // Handle error if needed
    }
  }

  private func toggleFavorite(_ conversation: Conversation) async {
    do {
      let updatedConversation = try await dataSource.toggleFavorite(
        client: client, conversation: conversation)
      updateConversation(updatedConversation)
    } catch {
      // Handle error if needed
    }
  }

  private func toggleBookmark(_ conversation: Conversation) async {
    do {
      let updatedConversation = try await dataSource.toggleBookmark(
        client: client, conversation: conversation)
      updateConversation(updatedConversation)
    } catch {
      // Handle error if needed
    }
  }

  private func updateConversation(_ conversation: Conversation) {
    if case .display(let conversations, let hasNextPage) = viewState {
      if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
        var updatedConversations = conversations
        updatedConversations[index] = conversation
        viewState = .display(conversations: updatedConversations, hasNextPage: hasNextPage)
      }
    }
  }
}
