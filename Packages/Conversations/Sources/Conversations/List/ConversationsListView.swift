import SwiftUI
import Network
import Models
import DesignSystem
import Shimmer
import Env

public struct ConversationsListView: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme
  
  @StateObject private var viewModel = ConversationsListViewModel()
  
  public init() { }
  
  private var conversations: [Conversation] {
    if viewModel.isLoadingFirstPage {
      return Conversation.placeholders()
    }
    return viewModel.conversations
  }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        if !conversations.isEmpty || viewModel.isLoadingFirstPage {
          ForEach(conversations) { conversation in
            if viewModel.isLoadingFirstPage {
              ConversationsListRow(conversation: conversation, viewModel: viewModel)
                .padding(.horizontal, .layoutPadding)
                .redacted(reason: .placeholder)
                .shimmering()
            } else {
              ConversationsListRow(conversation: conversation, viewModel: viewModel)
                .padding(.horizontal, .layoutPadding)
            }
            Divider()
          }
        } else if conversations.isEmpty && !viewModel.isLoadingFirstPage && !viewModel.isError {
          EmptyView(iconName: "tray",
                    title: "Inbox Zero",
                    message: "Looking for some social media love? You'll find all your direct messages and private mentions right here. Happy messaging! 📱❤️")
        } else if viewModel.isError {
          ErrorView(title: "An error occurred",
                    message: "Error while loading your messages",
                    buttonTitle: "Retry") {
            Task {
              await viewModel.fetchConversations()
            }
          }
        }
      }
      .padding(.top, .layoutPadding)
    }
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .navigationTitle("Direct Messages")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      StatusEditorToolbarItem(visibility: .direct)
    }
    .onChange(of: watcher.latestEvent?.id) { id in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent)
      }
    }
    .refreshable {
      await viewModel.fetchConversations()
    }
    .onAppear {
      viewModel.client = client
      if client.isAuth {
        Task {
          await viewModel.fetchConversations()
        }
      }
    }
  }
}
