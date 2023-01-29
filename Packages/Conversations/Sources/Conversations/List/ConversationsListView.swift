import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct ConversationsListView: View {
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme
  
  @StateObject private var viewModel = ConversationsListViewModel()
  
  public init() {}
  
  private var conversations: [Conversation] {
    if viewModel.isLoadingFirstPage {
      return Conversation.placeholders()
    }
    return viewModel.conversations
  }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        Group {
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
                      title: "conversations.empty.title",
                      message: "conversations.empty.message")
          } else if viewModel.isError {
            ErrorView(title: "conversations.error.title",
                      message: "conversations.error.message",
                      buttonTitle: "conversations.error.button") {
              Task {
                await viewModel.fetchConversations()
              }
            }
          }
          
          if viewModel.nextPage != nil {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
            .onAppear {
              if !viewModel.isLoadingNextPage {
                Task {
                  await viewModel.fetchNextPage()
                }
              }
            }
          }
        }
        .frame(maxWidth: .maxColumnWidth)
      }
      .padding(.top, .layoutPadding)
    }
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .navigationTitle("conversations.navigation-title")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      StatusEditorToolbarItem(visibility: .direct)
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
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
