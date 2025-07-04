import DesignSystem
import Env
import Models
import NetworkClient
import NukeUI
import SwiftUI

@MainActor
public struct ConversationDetailView: View {
  private enum Constants {
    static let bottomAnchor = "bottom"
  }

  @Environment(QuickLook.self) private var quickLook
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher

  @State private var dataSource: ConversationDetailDataSource
  @State private var viewState: ConversationDetailState = .loading
  @State private var newMessageText: String = ""
  @State private var isSendingMessage: Bool = false
  @State private var previousClientId: String?

  @FocusState private var isMessageFieldFocused: Bool

  @State private var scrollProxy: ScrollViewProxy?
  @State private var didAppear: Bool = false

  public init(conversation: Conversation) {
    _dataSource = .init(initialValue: .init(conversation: conversation))
    _viewState = .init(initialValue: .loading)
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          conversationMessagesView
          bottomAnchorView
        }
        .padding(.horizontal, .layoutPadding)
      }
      #if !os(visionOS)
        .scrollDismissesKeyboard(.interactively)
      #endif
      .safeAreaInset(edge: .bottom) {
        if case .display(_, let conversation) = viewState {
          ConversationInputView(
            newMessageText: $newMessageText,
            conversation: conversation,
            isSendingMessage: isSendingMessage,
            onSendMessage: {
              await postMessage()
            },
            isMessageFieldFocused: $isMessageFieldFocused
          )
        }
      }
      .onAppear {
        scrollProxy = proxy
        isMessageFieldFocused = true
        if !didAppear {
          didAppear = true
          Task {
            await fetchMessages()
            DispatchQueue.main.async {
              withAnimation {
                proxy.scrollTo(Constants.bottomAnchor, anchor: .bottom)
              }
            }
          }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .toolbar {
      ToolbarItem(placement: .principal) {
        if case .display(_, let conversation) = viewState {
          if conversation.accounts.count == 1,
            let account = conversation.accounts.first
          {
            EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
              .font(.scaledHeadline)
              .foregroundColor(theme.labelColor)
              .emojiText.size(Font.scaledHeadlineFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
          } else {
            Text("Direct message with \(conversation.accounts.count) people")
              .font(.scaledHeadline)
          }
        }
      }
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent {
        Task {
          await handleStreamEvent(latestEvent)
        }
      }
    }
    .onChange(of: client) { _, _ in
      _ = routerPath.path.removeLast()
    }
  }

  @ViewBuilder
  private var conversationMessagesView: some View {
    switch viewState {
    case .loading:
      loadingView

    case .display(let messages, let conversation):
      ForEach(messages) { message in
        ConversationMessageView(
          message: message,
          conversation: conversation
        )
        .padding(.vertical, 4)
        .id(message.id)
      }

    case .error:
      ErrorView(
        title: "conversations.error.title",
        message: "conversations.error.message",
        buttonTitle: "conversations.error.button"
      ) {
        await fetchMessages()
      }
    }
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { message in
      ConversationMessageView(
        message: message,
        conversation: Conversation.placeholder()
      )
      .redacted(reason: .placeholder)
      .allowsHitTesting(false)
      .padding(.vertical, 4)
    }
  }

  private var bottomAnchorView: some View {
    Rectangle()
      .fill(Color.clear)
      .frame(height: 10)
      .id(Constants.bottomAnchor)
      .accessibilityHidden(true)
  }

  // MARK: - Helper Methods

  private func fetchMessages() async {
    do {
      let result = try await dataSource.fetchMessages(client: client)
      viewState = .display(messages: result.messages, conversation: result.conversation)
    } catch {
      viewState = .error(error: error)
    }
  }

  private func postMessage() async {
    guard !isSendingMessage, !newMessageText.isEmpty else { return }

    isSendingMessage = true

    do {
      let result = try await dataSource.postMessage(
        client: client,
        messageText: newMessageText
      )

      withAnimation {
        viewState = .display(messages: result.messages, conversation: result.conversation)
        newMessageText = ""
        isSendingMessage = false
      }

      // Scroll to bottom after sending
      DispatchQueue.main.async {
        withAnimation {
          scrollProxy?.scrollTo(Constants.bottomAnchor, anchor: .bottom)
        }
      }
    } catch {
      isSendingMessage = false
    }
  }

  private func handleStreamEvent(_ event: any StreamEvent) async {
    if let result = dataSource.handleStreamEvent(event: event) {
      withAnimation {
        viewState = .display(messages: result.messages, conversation: result.conversation)
      }

      // Scroll to bottom for new messages
      DispatchQueue.main.async {
        withAnimation {
          scrollProxy?.scrollTo(Constants.bottomAnchor, anchor: .bottom)
        }
      }
    }
  }
}
