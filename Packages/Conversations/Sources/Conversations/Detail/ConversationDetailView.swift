import DesignSystem
import Env
import Models
import Network
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
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher

  @State private var viewModel: ConversationDetailViewModel

  @FocusState private var isMessageFieldFocused: Bool

  @State private var scrollProxy: ScrollViewProxy?
  @State private var didAppear: Bool = false

  public init(conversation: Conversation) {
    _viewModel = .init(initialValue: .init(conversation: conversation))
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          if viewModel.isLoadingMessages {
            loadingView
          }
          ForEach(viewModel.messages) { message in
            ConversationMessageView(
              message: message,
              conversation: viewModel.conversation
            )
            .padding(.vertical, 4)
            .id(message.id)
          }
          bottomAnchorView
        }
        .padding(.horizontal, .layoutPadding)
      }
      #if !os(visionOS)
        .scrollDismissesKeyboard(.interactively)
      #endif
      .safeAreaInset(edge: .bottom) {
        ConversationInputView(
          newMessageText: $viewModel.newMessageText,
          conversation: viewModel.conversation,
          isSendingMessage: viewModel.isSendingMessage,
          onSendMessage: {
            await viewModel.postMessage()
          },
          isMessageFieldFocused: $isMessageFieldFocused
        )
      }
      .onAppear {
        scrollProxy = proxy
        viewModel.client = client
        isMessageFieldFocused = true
        if !didAppear {
          didAppear = true
          Task {
            await viewModel.fetchMessages()
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
        if viewModel.conversation.accounts.count == 1,
          let account = viewModel.conversation.accounts.first
        {
          EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
            .font(.scaledHeadline)
            .foregroundColor(theme.labelColor)
            .emojiText.size(Font.scaledHeadlineFont.emojiSize)
            .emojiText.baselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
        } else {
          Text("Direct message with \(viewModel.conversation.accounts.count) people")
            .font(.scaledHeadline)
        }
      }
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent)
        DispatchQueue.main.async {
          withAnimation {
            scrollProxy?.scrollTo(Constants.bottomAnchor, anchor: .bottom)
          }
        }
      }
    }
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { message in
      ConversationMessageView(message: message, conversation: viewModel.conversation)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .padding(.vertical, 4)
    }
  }

  private var bottomAnchorView: some View {
    Rectangle()
      .fill(Color.clear)
      .frame(height: 40)
      .id(Constants.bottomAnchor)
      .accessibilityHidden(true)
  }
}
