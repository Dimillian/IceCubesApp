import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI

@MainActor
struct ConversationMessageView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(QuickLook.self) private var quickLook
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme

  let message: Status
  let conversation: Conversation

  @State private var isLiked: Bool = false
  @State private var isBookmarked: Bool = false

  var body: some View {
    let isOwnMessage = message.account.id == currentAccount.account?.id
    VStack {
      HStack(alignment: .bottom) {
        if isOwnMessage {
          Spacer()
        } else {
          AvatarView(message.account.avatar)
            .onTapGesture {
              routerPath.navigate(to: .accountDetailWithAccount(account: message.account))
            }
        }
        VStack(alignment: .leading) {
          EmojiTextApp(message.content, emojis: message.emojis)
            .font(.scaledBody)
            .foregroundColor(theme.labelColor)
            .emojiText.size(Font.scaledBodyFont.emojiSize)
            .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
            .padding(6)
            .environment(\.openURL, OpenURLAction { url in
              routerPath.handleStatus(status: message, url: url)
            })
        }
        #if os(visionOS)
        .background(isOwnMessage ? Material.ultraThick : Material.regular)
        #else
        .background(isOwnMessage ? theme.tintColor.opacity(0.2) : theme.secondaryBackgroundColor)
        #endif
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

      if message.id == String(conversation.lastStatus?.id ?? "") {
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
          .foregroundStyle(.secondary)
          if !isOwnMessage {
            Spacer()
          }
        }
      }
    }
    .onAppear {
      isLiked = message.favourited == true
      isBookmarked = message.bookmarked == true
    }
  }

  @ViewBuilder
  private var contextMenu: some View {
    Button {
      routerPath.navigate(to: .statusDetail(id: message.id))
    } label: {
      Label("conversations.action.view-detail", systemImage: "arrow.forward")
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
    Button { Task {
      do {
        let status: Status
        if isBookmarked {
          status = try await client.post(endpoint: Statuses.unbookmark(id: message.id))
        } else {
          status = try await client.post(endpoint: Statuses.bookmark(id: message.id))
        }
        withAnimation {
          isBookmarked = status.bookmarked == true
        }
      } catch {}
    } } label: {
      Label(isBookmarked ? "status.action.unbookmark" : "status.action.bookmark",
            systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
    }
    Divider()
    if message.account.id == currentAccount.account?.id {
      Button("status.action.delete", role: .destructive) {
        Task {
          _ = try await client.delete(endpoint: Statuses.status(id: message.id))
        }
      }
    } else {
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

  private func makeImageRequest(for url: URL, size: CGSize) -> ImageRequest {
    ImageRequest(url: url, processors: [.resize(size: size)])
  }

  private func mediaWidth(proxy: GeometryProxy) -> CGFloat {
    var width = proxy.frame(in: .local).width
    if UIDevice.current.userInterfaceIdiom == .pad {
      width = width * 0.60
    }
    return width
  }

  private func makeMediaView(_ attachement: MediaAttachment) -> some View {
    GeometryReader { proxy in
      let width = mediaWidth(proxy: proxy)
      if let url = attachement.url {
        LazyImage(request: makeImageRequest(for: url,
                                            size: .init(width: width, height: 200)))
        { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: 200)
              .frame(maxWidth: width)
              .clipped()
              .cornerRadius(8)
              .padding(8)
          } else if state.isLoading {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray)
              .frame(height: 200)
          }
        }
      }
    }
    .frame(height: 200)
    .contentShape(Rectangle())
    .onTapGesture {
      #if targetEnvironment(macCatalyst) || os(visionOS)
        openWindow(value: WindowDestinationMedia.mediaViewer(attachments: [attachement],
                                                             selectedAttachment: attachement))
      #else
        quickLook.prepareFor(selectedMediaAttachment: attachement, mediaAttachments: [attachement])
      #endif
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
