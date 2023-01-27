import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI

struct ConversationMessageView: View {
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme

  let message: Status
  let conversation: Conversation

  @State private var isLiked: Bool = false

  var body: some View {
    let isOwnMessage = message.account.id == currentAccount.account?.id
    VStack {
      HStack(alignment: .bottom) {
        if isOwnMessage {
          Spacer()
        } else {
          AvatarView(url: message.account.avatar, size: .status)
            .onTapGesture {
              routerPath.navigate(to: .accountDetailWithAccount(account: message.account))
            }
        }
        VStack(alignment: .leading) {
          EmojiTextApp(message.content, emojis: message.emojis)
            .font(.scaledBody)
            .padding(6)
            .environment(\.openURL, OpenURLAction { url in
              routerPath.handleStatus(status: message, url: url)
            })
        }
        .background(isOwnMessage ? theme.tintColor.opacity(0.2) : theme.secondaryBackgroundColor)
        .cornerRadius(8)
        .padding(.leading, isOwnMessage ? 24 : 0)
        .padding(.trailing, isOwnMessage ? 0 : 24)
        .overlay {
          if isLiked, message.account.id != currentAccount.account?.id {
            likeView
          }
        }
        .contextMenu {
          contextMenu
        }

        if !isOwnMessage {
          Spacer()
        }
      }

      ForEach(message.mediaAttachments) { media in
        makeMediaView(media)
          .padding(.leading, isOwnMessage ? 24 : 0)
          .padding(.trailing, isOwnMessage ? 0 : 24)
      }

      if message.id == conversation.lastStatus.id {
        HStack {
          if isOwnMessage {
            Spacer()
          }
          Group {
            Text(message.createdAt.shortDateFormatted) +
              Text(" ")
            Text(message.createdAt.asDate, style: .time)
          }
          .font(.scaledFootnote)
          .foregroundColor(.gray)
          if !isOwnMessage {
            Spacer()
          }
        }
      }
    }
    .onAppear {
      isLiked = message.favourited == true
    }
  }

  @ViewBuilder
  private var contextMenu: some View {
    Button {
      routerPath.navigate(to: .statusDetail(id: message.id))
    } label: {
      Label("View detail", systemImage: "arrow.forward")
    }
    Button {
      UIPasteboard.general.string = message.content.asRawText
    } label: {
      Label("status.action.copy-text", systemImage: "doc.on.doc")
    }
    Button {
      Task {
        do {
          let status: Status
          if isLiked {
            status = try await client.post(endpoint: Statuses.unfavorite(id: message.id))
          } else {
            status = try await client.post(endpoint: Statuses.favorite(id: message.id))
          }
          withAnimation {
            isLiked = status.favourited == true
          }
        } catch {}
      }
    } label: {
      Label(isLiked ? "status.action.unfavorite" : "status.action.favorite",
            systemImage: isLiked ? "star.fill" : "star")
    }
    Divider()
    if message.account.id == currentAccount.account?.id {
      Button("status.action.delete", role: .destructive) {
        Task {
          _ = try await client.delete(endpoint: Statuses.status(id: message.id))
        }
      }
    }
  }

  private func makeMediaView(_ attachement: MediaAttachment) -> some View {
    LazyImage(url: attachement.url) { state in
      if let image = state.image {
        image
          .resizingMode(.aspectFill)
          .cornerRadius(8)
          .padding(8)
      } else if state.isLoading {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray)
          .frame(height: 200)
          .shimmering()
      }
    }
    .frame(height: 200)
    .contentShape(Rectangle())
    .onTapGesture {
      if let url = attachement.url {
        Task {
          await quickLook.prepareFor(urls: [url], selectedURL: url)
        }
      }
    }
  }

  private var likeView: some View {
    HStack {
      Spacer()
      VStack {
        Image(systemName: "star.fill")
          .foregroundColor(.yellow)
          .offset(x: -16, y: -7)
        Spacer()
      }
    }
  }
}
