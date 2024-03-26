import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct ConversationsListView: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(RouterPath.self) private var routerPath
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme

  @State private var viewModel = ConversationsListViewModel()

  @Binding var scrollToTopSignal: Int

  public init(scrollToTopSignal: Binding<Int>) {
    _scrollToTopSignal = scrollToTopSignal
  }

  private var conversations: Binding<[Conversation]> {
    if viewModel.isLoadingFirstPage {
      Binding.constant(Conversation.placeholders())
    } else {
      $viewModel.conversations
    }
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        scrollToTopView
        LazyVStack {
          Group {
            if !conversations.isEmpty || viewModel.isLoadingFirstPage {
              ForEach(conversations) { $conversation in
                if viewModel.isLoadingFirstPage {
                  ConversationsListRow(conversation: $conversation, viewModel: viewModel)
                    .padding(.horizontal, .layoutPadding)
                    .redacted(reason: .placeholder)
                    .allowsHitTesting(false)
                } else {
                  ConversationsListRow(conversation: $conversation, viewModel: viewModel)
                    .padding(.horizontal, .layoutPadding)
                }
                Divider()
              }
            } else if conversations.isEmpty, !viewModel.isLoadingFirstPage, !viewModel.isError {
              PlaceholderView(iconName: "tray",
                              title: "conversations.empty.title",
                              message: "conversations.empty.message")
            } else if viewModel.isError {
              ErrorView(title: "conversations.error.title",
                        message: "conversations.error.message",
                        buttonTitle: "conversations.error.button")
              {
                await viewModel.fetchConversations()
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
        }
        .padding(.top, .layoutPadding)
      }
      #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      #endif
      .navigationTitle("conversations.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
      .onChange(of: watcher.latestEvent?.id) {
        if let latestEvent = watcher.latestEvent {
          viewModel.handleEvent(event: latestEvent)
        }
      }
      .onChange(of: scrollToTopSignal) {
        withAnimation {
          proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
        }
      }
      .refreshable {
        // note: this Task wrapper should not be necessary, but it reportedly crashes without it
        // when refreshing on an empty list
        Task {
          SoundEffectManager.shared.playSound(.pull)
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
          await viewModel.fetchConversations()
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
          SoundEffectManager.shared.playSound(.refresh)
        }
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

  private var scrollToTopView: some View {
    ScrollToView()
      .frame(height: .scrollToViewHeight)
      .onAppear {
        viewModel.scrollToTopVisible = true
      }
      .onDisappear {
        viewModel.scrollToTopVisible = false
      }
  }
}
