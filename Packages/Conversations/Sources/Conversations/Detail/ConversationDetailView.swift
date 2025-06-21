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
        inputTextView
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

  @ViewBuilder
  private var inputTextView: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        HStack(alignment: .bottom, spacing: 8) {
          attachmentButton
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
          textField
          sendButton
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
        }
        .padding(8)
      }
    } else {
      VStack {
        HStack(alignment: .bottom, spacing: 8) {
          attachmentButton
          textField
          sendButton
        }
        .padding(8)
      }
      .background(.thinMaterial)
    }
  }

  @ViewBuilder
  private var attachmentButton: some View {
    if viewModel.conversation.lastStatus != nil {
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(
          status: viewModel.conversation.lastStatus!)
      } label: {
        if #available(iOS 26.0, *) {
          Image(systemName: "plus")
            .padding(6)
        } else {
          Image(systemName: "plus")
        }
      }
      .padding(.bottom, 7)
    }

  }

  @ViewBuilder
  private var textField: some View {
    if #available(iOS 26.0, *) {
      TextField(
        "conversations.new.message.placeholder", text: $viewModel.newMessageText, axis: .vertical
      )
      .font(.scaledBody)
      .focused($isMessageFieldFocused)
      .keyboardType(.default)
      .padding(12)
      .glassEffect(in: .rect(cornerRadius: 18))
      .padding(.bottom, 6)
    } else {
      TextField(
        "conversations.new.message.placeholder", text: $viewModel.newMessageText, axis: .vertical
      )
      .focused($isMessageFieldFocused)
      .keyboardType(.default)
      .backgroundStyle(.thickMaterial)
      .padding(6)
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(.gray, lineWidth: 1)
      )
      .font(.scaledBody)
    }
  }

  @ViewBuilder
  private var sendButton: some View {
    HStack {
      if !viewModel.newMessageText.isEmpty {
        Button {
          Task {
            guard !viewModel.isSendingMessage else { return }
            await viewModel.postMessage()
          }
        } label: {
          if #available(iOS 26.0, *) {
            HStack {
              if viewModel.isSendingMessage {
                ProgressView()
              } else {
                Image(systemName: "paperplane")
              }
            }
            .padding(6)
          } else {
            HStack {
              if viewModel.isSendingMessage {
                ProgressView()
              } else {
                Image(systemName: "paperplane")
              }
            }
          }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .padding(.bottom, 6)
        .animation(.bouncy, value: viewModel.isSendingMessage)
        .transition(.move(edge: .trailing))
      }
    }
  }
}
