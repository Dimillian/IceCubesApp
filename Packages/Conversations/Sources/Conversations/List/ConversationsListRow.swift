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
    Button {
      Task {
        await viewModel.markAsRead(conversation: conversation)
      }
      routerPath.navigate(to: .conversationDetail(conversation: conversation))
    } label: {
      VStack(alignment: .leading) {
        HStack(alignment: .top, spacing: 8) {
          AvatarView(url: conversation.accounts.first!.avatar)
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              EmojiTextApp(.init(stringValue: conversation.accounts.map { $0.safeDisplayName }.joined(separator: ", ")),
                           emojis: conversation.accounts.flatMap { $0.emojis })
                .font(.scaledSubheadline)
                .foregroundColor(theme.labelColor)
                .emojiSize(Font.scaledSubheadlineFont.emojiSize)
                .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
                .fontWeight(.semibold)
                .foregroundColor(theme.labelColor)
                .multilineTextAlignment(.leading)
              Spacer()
              if conversation.unread {
                Circle()
                  .foregroundColor(theme.tintColor)
                  .frame(width: 10, height: 10)
                  .accessibilityRepresentation {
                    Text("accessibility.tabs.messages.unread.label")
                  }
                  .accessibilitySortPriority(1)
              }
              if let message = conversation.lastStatus {
                Text(message.createdAt.relativeFormatted)
                  .font(.scaledFootnote)
              }
            }
            EmojiTextApp(conversation.lastStatus?.content ?? HTMLString(stringValue: ""), emojis: conversation.lastStatus?.emojis ?? [])
              .multilineTextAlignment(.leading)
              .font(.scaledBody)
              .foregroundColor(theme.labelColor)
              .emojiSize(Font.scaledBodyFont.emojiSize)
              .emojiBaselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
              .accessibilityLabel(conversation.lastStatus?.content.asRawText ?? "")
          }
          Spacer()
        }
        .padding(.top, 4)
        if conversation.lastStatus != nil {
          actionsView
            .padding(.bottom, 4)
            .accessibilityHidden(true)
        }
      }
      .contextMenu {
        contextMenu
          .accessibilityHidden(true)
      }
      .accessibilityElement(children: .combine)
      .accessibilityActions {
        replyAction
        contextMenu
        accessibilityActions
      }
      .accessibilityAction(.magicTap) {
        if let lastStatus = conversation.lastStatus {
          HapticManager.shared.fireHaptic(of: .notification(.success))
          routerPath.presentedSheet = .replyToStatusEditor(status: lastStatus)
        }
      }
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
    if conversation.unread {
      Button {
        Task {
          await viewModel.markAsRead(conversation: conversation)
        }
      } label: {
        Label("conversations.action.mark-read", systemImage: "eye")
      }
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

  // MARK: - Accessibility actions

  @ViewBuilder
  var replyAction: some View {
    if let lastStatus = conversation.lastStatus {
      Button("status.action.reply") {
        HapticManager.shared.fireHaptic(of: .notification(.success))
        routerPath.presentedSheet = .replyToStatusEditor(status: lastStatus)
      }
    } else {
      EmptyView()
    }
  }

  @ViewBuilder
  private var accessibilityActions: some View {
    if let lastStatus = conversation.lastStatus {
      if lastStatus.account.id != currentAccount.account?.id {
        Button("@\(lastStatus.account.username)") {
          HapticManager.shared.fireHaptic(of: .notification(.success))
          routerPath.navigate(to: .accountDetail(id: lastStatus.account.id))
        }
      }
      // Add in each detected link in the content
      ForEach(lastStatus.content.links) { link in
        switch link.type {
        case .url:
          if UIApplication.shared.canOpenURL(link.url) {
            Button("accessibility.tabs.timeline.content-link-\(link.title)") {
              HapticManager.shared.fireHaptic(of: .notification(.success))
              _ = routerPath.handle(url: link.url)
            }
          }
        case .hashtag:
          Button("accessibility.tabs.timeline.content-hashtag-\(link.title)") {
            HapticManager.shared.fireHaptic(of: .notification(.success))
            _ = routerPath.handle(url: link.url)
          }
        case .mention:
          Button("\(link.title)") {
            HapticManager.shared.fireHaptic(of: .notification(.success))
            _ = routerPath.handle(url: link.url)
          }
        }
      }
    }
  }
}
