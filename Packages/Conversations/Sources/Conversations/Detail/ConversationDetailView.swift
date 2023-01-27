import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI

public struct ConversationDetailView: View {
  private enum Constants {
    static let bottomAnchor = "bottom"
  }

  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var watcher: StreamWatcher

  @StateObject private var viewModel: ConversationDetailViewModel

  @FocusState private var isMessageFieldFocused: Bool

  @State private var scrollProxy: ScrollViewProxy?
  @State private var didAppear: Bool = false

  public init(conversation: Conversation) {
    _viewModel = StateObject(wrappedValue: .init(conversation: conversation))
  }

  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .bottom) {
        ScrollView {
          LazyVStack {
            if viewModel.isLoadingMessages {
              loadingView
            }
            ForEach(viewModel.messages) { message in
              ConversationMessageView(message: message,
                                      conversation: viewModel.conversation)
                .padding(.vertical, 4)
                .id(message.id)
            }
            bottomAnchorView
          }
          .padding(.horizontal, .layoutPadding)
          .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
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
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .toolbar {
      ToolbarItem(placement: .principal) {
        if viewModel.conversation.accounts.count == 1,
           let account = viewModel.conversation.accounts.first
        {
          EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
            .font(.scaledHeadline)
        } else {
          Text("Direct message with \(viewModel.conversation.accounts.count) people")
            .font(.scaledHeadline)
        }
      }
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
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
        .shimmering()
        .padding(.vertical, 4)
    }
  }

  private var bottomAnchorView: some View {
    Rectangle()
      .fill(Color.clear)
      .frame(height: 40)
      .id(Constants.bottomAnchor)
  }

  private var inputTextView: some View {
    VStack {
      HStack(alignment: .bottom, spacing: 8) {
        Button {
          routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.conversation.lastStatus)
        } label: {
          Image(systemName: "plus")
        }
        .padding(.bottom, 7)

        TextField("conversations.new.message.placeholder", text: $viewModel.newMessageText, axis: .vertical)
          .focused($isMessageFieldFocused)
          .keyboardType(.default)
          .backgroundStyle(.thickMaterial)
          .padding(6)
          .overlay(
            RoundedRectangle(cornerRadius: 14)
              .stroke(.gray, lineWidth: 1)
          )
          .font(.scaledBody)
        if !viewModel.newMessageText.isEmpty {
          Button {
            Task {
              await viewModel.postMessage()
            }
          } label: {
            if viewModel.isSendingMessage {
              ProgressView()
            } else {
              Image(systemName: "paperplane")
            }
          }
          .keyboardShortcut(.return, modifiers: .command)
          .padding(.bottom, 6)
        }
      }
      .padding(8)
    }
    .background(.thinMaterial)
  }
}
