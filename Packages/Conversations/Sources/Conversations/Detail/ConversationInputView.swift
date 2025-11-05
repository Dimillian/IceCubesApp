import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct ConversationInputView: View {
  @Environment(RouterPath.self) private var routerPath

  @Binding var newMessageText: String
  var conversation: Conversation?
  var isSendingMessage: Bool
  var onSendMessage: () async -> Void
  @FocusState.Binding var isMessageFieldFocused: Bool

  var body: some View {
    inputTextView
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
            .buttonStyle(.glassProminent)
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
    if let conversation, let lastStatus = conversation.lastStatus {
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(status: lastStatus)
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
        "conversations.new.message.placeholder", text: $newMessageText, axis: .vertical
      )
      .font(.scaledBody)
      .focused($isMessageFieldFocused)
      .keyboardType(.default)
      .padding(12)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
      .padding(.bottom, 6)
    } else {
      TextField(
        "conversations.new.message.placeholder", text: $newMessageText, axis: .vertical
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
      if !newMessageText.isEmpty {
        Button {
          Task {
            guard !isSendingMessage else { return }
            await onSendMessage()
          }
        } label: {
          if #available(iOS 26.0, *) {
            HStack {
              if isSendingMessage {
                ProgressView()
              } else {
                Image(systemName: "paperplane")
              }
            }
            .padding(6)
          } else {
            HStack {
              if isSendingMessage {
                ProgressView()
              } else {
                Image(systemName: "paperplane")
              }
            }
          }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .padding(.bottom, 6)
        .animation(.bouncy, value: isSendingMessage)
        .transition(.move(edge: .trailing))
      }
    }
  }
}
