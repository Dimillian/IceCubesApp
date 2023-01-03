import SwiftUI
import Models
import Env
import DesignSystem
import Network
import Shimmer

public struct StatusRowView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  @StateObject var viewModel: StatusRowViewModel
  
  public init(viewModel: StatusRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    HStack(alignment: .top, spacing: .statusColumnsSpacing) {
      if !viewModel.isCompact,
         theme.avatarPosition == .leading,
         let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
        Button {
          routeurPath.navigate(to: .accountDetailWithAccount(account: status.account))
        } label: {
          AvatarView(url: status.account.avatar, size: .status)
        }
      }
      VStack(alignment: .leading) {
        if !viewModel.isCompact {
          reblogView
           replyView
        }
        statusView
        if !viewModel.isCompact {
          StatusActionsView(viewModel: viewModel)
            .padding(.vertical, 8)
            .tint(viewModel.isFocused ? theme.tintColor : .gray)
            .contentShape(Rectangle())
            .onTapGesture {
              routeurPath.navigate(to: .statusDetail(id: viewModel.status.reblog?.id ?? viewModel.status.id))
            }
        }
      }
    }
    .onAppear {
      viewModel.client = client
      if !viewModel.isCompact, viewModel.embededStatus == nil {
        Task {
          await viewModel.loadEmbededStatus()
        }
      }
    }
    .contextMenu {
      contextMenu
    }
  }
  
  @ViewBuilder
  private var reblogView: some View {
    if viewModel.status.reblog != nil {
      HStack(spacing: 2) {
        Image(systemName:"arrow.left.arrow.right.circle.fill")
        AvatarView(url: viewModel.status.account.avatar, size: .boost)
        viewModel.status.account.displayNameWithEmojis
        Text("boosted")
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        routeurPath.navigate(to: .accountDetailWithAccount(account: viewModel.status.account))
      }
    }
  }
  
  @ViewBuilder
  var replyView: some View {
    if let accountId = viewModel.status.inReplyToAccountId,
       let mention = viewModel.status.mentions.first(where: { $0.id == accountId}) {
      HStack(spacing: 2) {
        Image(systemName:"arrowshape.turn.up.left.fill")
        Text("Replied to")
        Text(mention.username)
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        routeurPath.navigate(to: .accountDetail(id: mention.id))
      }
    }
  }
  
  private var statusView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
        if !viewModel.isCompact {
          HStack(alignment: .top) {
            Button {
              routeurPath.navigate(to: .accountDetailWithAccount(account: status.account))
            } label: {
              accountView(status: status)
            }.buttonStyle(.plain)
            Spacer()
            menuButton
          }
        }
        makeStatusContentView(status: status)      }
    }
  }
  
  private func makeStatusContentView(status: AnyStatus) -> some View {
    Group {
      if !viewModel.status.spoilerText.isEmpty {
        Text(status.spoilerText)
          .font(.body)
      }
      if viewModel.displaySpoiler {
        Button {
          withAnimation {
            viewModel.displaySpoiler = false
          }
        } label: {
          Text("Show more")
        }
        .buttonStyle(.bordered)
      } else {
        Text(status.content.asSafeAttributedString)
          .font(.body)
          .environment(\.openURL, OpenURLAction { url in
            routeurPath.handleStatus(status: status, url: url)
          })
        
        if !reasons.contains(.placeholder) {
          if !viewModel.isCompact, !viewModel.isEmbedLoading, let embed = viewModel.embededStatus {
            StatusEmbededView(status: embed)
          } else if viewModel.isEmbedLoading, !viewModel.isCompact {
            StatusEmbededView(status: .placeholder())
              .redacted(reason: .placeholder)
              .shimmering()
          }
        }
        
        if let poll = status.poll {
          StatusPollView(poll: poll)
        }
        
        if !status.mediaAttachments.isEmpty {
          StatusMediaPreviewView(attachements: status.mediaAttachments, isCompact: viewModel.isCompact)
            .padding(.vertical, 4)
        }
        if let card = status.card, viewModel.embededStatus?.url != status.card?.url, !viewModel.isEmbedLoading {
          StatusCardView(card: card)
        }
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      routeurPath.navigate(to: .statusDetail(id: viewModel.status.reblog?.id ?? viewModel.status.id))
    }
  }
  
  @ViewBuilder
  private func accountView(status: AnyStatus) -> some View {
    HStack(alignment: .center) {
      if theme.avatarPosition == .top {
        AvatarView(url: status.account.avatar, size: .status)
      }
      VStack(alignment: .leading, spacing: 0) {
        status.account.displayNameWithEmojis
          .font(.headline)
          .fontWeight(.semibold)
        Group {
          Text("@\(status.account.acct)") +
          Text(" ⸱ ") +
          Text(status.createdAt.formatted) +
          Text(" ⸱ ") +
          Text(Image(systemName: viewModel.status.visibility.iconName))
        }
        .font(.footnote)
        .foregroundColor(.gray)
      }
    }
  }
  
  private var menuButton: some View {
    Menu {
      contextMenu
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 30, height: 30)
    }
    .foregroundColor(.gray)
    .contentShape(Rectangle())
  }
  
  @ViewBuilder
  private var contextMenu: some View {
    Button { Task {
      if viewModel.isFavourited {
        await viewModel.unFavourite()
      } else {
        await viewModel.favourite()
      }
    } } label: {
      Label(viewModel.isFavourited ? "Unfavorite" : "Favorite", systemImage: "star")
    }
    Button { Task {
      if viewModel.isReblogged {
        await viewModel.unReblog()
      } else {
        await viewModel.reblog()
      }
    } } label: {
      Label(viewModel.isReblogged ? "Unboost" : "Boost", systemImage: "arrow.left.arrow.right.circle")
    }
    Button {
      routeurPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
    } label: {
      Label("Quote this post", systemImage: "quote.bubble")
    }
    
    if let url = viewModel.status.reblog?.url ?? viewModel.status.url {
      Button { UIApplication.shared.open(url)  } label: {
        Label("View in Browser", systemImage: "safari")
      }
    }
    
    if account.account?.id == viewModel.status.account.id {
      Button {
        routeurPath.presentedSheet = .editStatusEditor(status: viewModel.status)
      } label: {
        Label("Edit", systemImage: "pencil")
      }
      Button(role: .destructive) { Task { await viewModel.delete() } } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}
