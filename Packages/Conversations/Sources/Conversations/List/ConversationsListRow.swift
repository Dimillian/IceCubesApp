import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct ConversationsListRow: View {
  @Environment(\.openWindow) private var openWindow

  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount

  @Binding var conversation: Conversation
  let onMarkAsRead: (Conversation) async -> Void
  let onDelete: (Conversation) async -> Void
  let onFavorite: (Conversation) async -> Void
  let onBookmark: (Conversation) async -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 8) {
        AvatarView(conversation.accounts.first!.avatar)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            EmojiTextApp(
              .init(
                stringValue: conversation.accounts.map(\.safeDisplayName).joined(separator: ", ")),
              emojis: conversation.accounts.flatMap(\.emojis)
            )
            .font(.scaledSubheadline)
            .foregroundColor(theme.labelColor)
            .emojiText.size(Font.scaledSubheadlineFont.emojiSize)
            .emojiText.baselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
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
              HStack {
                Text(message.createdAt.relativeFormatted)
                Image(systemName: "chevron.right")
              }
              .foregroundStyle(.secondary)
              .font(.scaledFootnote)
            }
          }
          EmojiTextApp(
            conversation.lastStatus?.content ?? HTMLString(stringValue: ""),
            emojis: conversation.lastStatus?.emojis ?? []
          )
          .multilineTextAlignment(.leading)
          .font(.scaledBody)
          .foregroundColor(theme.labelColor)
          .emojiText.size(Font.scaledBodyFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
          .accessibilityLabel(conversation.lastStatus?.content.asRawText ?? "")
        }
        Spacer()
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
        HapticManager.shared.fireHaptic(.notification(.success))
        #if targetEnvironment(macCatalyst) || os(visionOS)
          openWindow(value: WindowDestinationEditor.replyToStatusEditor(status: lastStatus))
        #else
          routerPath.presentedSheet = .replyToStatusEditor(status: lastStatus)
        #endif
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      Task {
        await onMarkAsRead(conversation)
      }
      routerPath.navigate(to: .conversationDetail(conversation: conversation))
    }
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
      Button {
        if let lastStatus = conversation.lastStatus {
          HapticManager.shared.fireHaptic(.notification(.success))
          #if targetEnvironment(macCatalyst) || os(visionOS)
            openWindow(value: WindowDestinationEditor.replyToStatusEditor(status: lastStatus))
          #else
            routerPath.presentedSheet = .replyToStatusEditor(status: lastStatus)
          #endif
        }
      } label: {
        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
      }
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      markAsReadAction
      deleteAction
    }
    .listRowInsets(
      .init(
        top: 16,
        leading: .layoutPadding + 4,
        bottom: 16,
        trailing: .layoutPadding)
    )
  }

  @ViewBuilder
  private var contextMenu: some View {
    markAsReadAction

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
            routerPath.presentedSheet = .mentionStatusEditor(
              account: message.reblog?.account ?? message.account, visibility: .pub)
          } label: {
            Label("status.action.mention", systemImage: "at")
          }
        }
        Section {
          Button(role: .destructive) {
            routerPath.presentedSheet = .report(status: message.reblogAsAsStatus ?? message)
          } label: {
            Label("status.action.report", systemImage: "exclamationmark.bubble")
              .tint(.red)
          }
        }
      }
    }
    deleteAction
  }

  @ViewBuilder
  private var markAsReadAction: some View {
    if conversation.unread {
      Button {
        Task {
          await onMarkAsRead(conversation)
        }
      } label: {
        Label("conversations.action.mark-read", systemImage: "eye")
      }
      .tint(.blue)
    }
  }

  private var deleteAction: some View {
    Button(role: .destructive) {
      Task {
        await onDelete(conversation)
      }
    } label: {
      Label("conversations.action.delete", systemImage: "trash")
        .tint(.red)
    }
  }

  @ViewBuilder
  private var likeAndBookmark: some View {
    Button {
      Task {
        await onFavorite(conversation)
      }
    } label: {
      Label(
        conversation.lastStatus?.favourited ?? false
          ? "status.action.unfavorite" : "status.action.favorite",
        systemImage: conversation.lastStatus?.favourited ?? false ? "star.fill" : "star")
    }
    Button {
      Task {
        await onBookmark(conversation)
      }
    } label: {
      Label(
        conversation.lastStatus?.bookmarked ?? false
          ? "status.action.unbookmark" : "status.action.bookmark",
        systemImage: conversation.lastStatus?.bookmarked ?? false ? "bookmark.fill" : "bookmark")
    }
  }

  // MARK: - Accessibility actions

  @ViewBuilder
  var replyAction: some View {
    if let lastStatus = conversation.lastStatus {
      Button("status.action.reply") {
        HapticManager.shared.fireHaptic(.notification(.success))
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
          HapticManager.shared.fireHaptic(.notification(.success))
          routerPath.navigate(to: .accountDetail(id: lastStatus.account.id))
        }
      }
      // Add in each detected link in the content
      ForEach(lastStatus.content.links) { link in
        switch link.type {
        case .url:
          if UIApplication.shared.canOpenURL(link.url) {
            Button("accessibility.tabs.timeline.content-link-\(link.title)") {
              HapticManager.shared.fireHaptic(.notification(.success))
              _ = routerPath.handle(url: link.url)
            }
          }
        case .hashtag:
          Button("accessibility.tabs.timeline.content-hashtag-\(link.title)") {
            HapticManager.shared.fireHaptic(.notification(.success))
            _ = routerPath.handle(url: link.url)
          }
        case .mention:
          Button("\(link.title)") {
            HapticManager.shared.fireHaptic(.notification(.success))
            _ = routerPath.handle(url: link.url)
          }
        }
      }
    }
  }
}
