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
  @EnvironmentObject private var currentAccount: CurrentAccount

  @Binding var conversation: Conversation
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
              .emojiSize(Font.scaledSubheadlinePointSize)
              .fontWeight(.semibold)
              .foregroundColor(theme.labelColor)
              .multilineTextAlignment(.leading)
            Spacer()
            if conversation.unread {
              Circle()
                .foregroundColor(theme.tintColor)
                .frame(width: 10, height: 10)
            }
            if let message = conversation.lastStatus {
              Text(message.createdAt.relativeFormatted)
                .font(.scaledFootnote)
            }
          }
          EmojiTextApp(conversation.lastStatus?.content ?? HTMLString(stringValue: ""), emojis: conversation.lastStatus?.emojis ?? [])
            .multilineTextAlignment(.leading)
            .font(.scaledBody)
            .emojiSize(Font.scaledBodyPointSize)
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
      if conversation.lastStatus != nil {
        actionsView
          .padding(.bottom, 4)
      }
    }
    .contextMenu {
      contextMenu
    }
  }

  private var actionsView: some View {
    HStack(spacing: 12) {
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(status: conversation.lastStatus!)
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

    if let message = conversation.lastStatus {
      Section("conversations.latest.message") {
        Button {
          UIPasteboard.general.string = message.content.asRawText
        } label: {
          Label("status.action.copy-text", systemImage: "doc.on.doc")
        }
        likeAndBookmark
      }
      Divider()
      if message.account.id != currentAccount.account?.id {
        Section(message.reblog?.account.acct ?? message.account.acct) {
          Button {
            routerPath.presentedSheet = .mentionStatusEditor(account: message.reblog?.account ?? message.account, visibility: .pub)
          } label: {
            Label("status.action.mention", systemImage: "at")
          }
        }
        Section {
          Button(role: .destructive) {
            routerPath.presentedSheet = .report(status: message.reblogAsAsStatus ?? message)
          } label: {
            Label("status.action.report", systemImage: "exclamationmark.bubble")
          }
        }
      }
    }

    Button(role: .destructive) {
      Task {
        await viewModel.delete(conversation: conversation)
      }
    } label: {
      Label("conversations.action.delete", systemImage: "trash")
    }
  }

  @ViewBuilder
  private var likeAndBookmark: some View {
    Button {
      Task {
        await viewModel.favorite(conversation: conversation)
      }
    } label: {
      Label(conversation.lastStatus?.favourited ?? false ? "status.action.unfavorite" : "status.action.favorite",
            systemImage: conversation.lastStatus?.favourited ?? false ? "star.fill" : "star")
    }
    Button {
      Task {
        await viewModel.bookmark(conversation: conversation)
      }
    } label: {
      Label(conversation.lastStatus?.bookmarked ?? false ? "status.action.unbookmark" : "status.action.bookmark",
            systemImage: conversation.lastStatus?.bookmarked ?? false ? "bookmark.fill" : "bookmark")
    }
  }
}
