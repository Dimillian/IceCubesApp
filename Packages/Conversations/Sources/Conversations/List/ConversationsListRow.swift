import Accounts
import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct ConversationsListRow: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var theme: Theme

  let conversation: Conversation
  @ObservedObject var viewModel: ConversationsListViewModel

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 8) {
        AvatarView(url: conversation.accounts.first!.avatar)
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            EmojiTextApp(.init(stringValue: conversation.accounts.map { $0.safeDisplayName }.joined(separator: ", ")),
                         emojis: conversation.accounts.flatMap { $0.emojis })
              .font(.scaledSubheadline)
              .fontWeight(.semibold)
              .foregroundColor(theme.labelColor)
              .multilineTextAlignment(.leading)
            Spacer()
            if conversation.unread {
              Circle()
                .foregroundColor(theme.tintColor)
                .frame(width: 10, height: 10)
            }
            Text(conversation.lastStatus.createdAt.relativeFormatted)
              .font(.scaledFootnote)
          }
          EmojiTextApp(conversation.lastStatus.content, emojis: conversation.lastStatus.emojis)
            .multilineTextAlignment(.leading)
            .font(.scaledBody)
        }
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture {
        Task {
          await viewModel.markAsRead(conversation: conversation)
        }
        routerPath.navigate(to: .conversationDetail(conversation: conversation))
      }
      .padding(.top, 4)
      actionsView
        .padding(.bottom, 4)
    }
    .contextMenu {
      contextMenu
    }
  }

  private var actionsView: some View {
    HStack(spacing: 12) {
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(status: conversation.lastStatus)
      } label: {
        Image(systemName: "arrowshape.turn.up.left.fill")
      }
      Menu {
        contextMenu
      } label: {
        Image(systemName: "ellipsis")
          .frame(width: 30, height: 30)
          .contentShape(Rectangle())
      }
    }
    .padding(.leading, 48)
    .foregroundColor(.gray)
  }

  @ViewBuilder
  private var contextMenu: some View {
    Button {
      Task {
        await viewModel.markAsRead(conversation: conversation)
      }
    } label: {
      Label("conversations.action.mark-read", systemImage: "eye")
    }

    Button(role: .destructive) {
      Task {
        await viewModel.delete(conversation: conversation)
      }
    } label: {
      Label("conversations.action.delete", systemImage: "trash")
    }
  }
}
