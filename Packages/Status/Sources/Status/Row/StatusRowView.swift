import DesignSystem
import EmojiText
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct StatusRowView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  @StateObject var viewModel: StatusRowViewModel

  public init(viewModel: StatusRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  public var body: some View {
    if viewModel.isFiltered, let filter = viewModel.filter {
      switch filter.filter.filterAction {
      case .warn:
        makeFilterView(filter: filter.filter)
      case .hide:
        EmptyView()
      }
    } else {
      HStack(alignment: .top, spacing: .statusColumnsSpacing) {
        if !viewModel.isCompact,
           theme.avatarPosition == .leading,
           let status: AnyStatus = viewModel.status.reblog ?? viewModel.status
        {
          Button {
            routerPath.navigate(to: .accountDetailWithAccount(account: status.account))
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
          if viewModel.showActions && !viewModel.isRemote, theme.statusActionsDisplay != .none {
            StatusActionsView(viewModel: viewModel)
              .padding(.top, 8)
              .tint(viewModel.isFocused ? theme.tintColor : .gray)
              .contentShape(Rectangle())
              .onTapGesture {
                viewModel.navigateToDetail(routerPath: routerPath)
              }
          }
        }
      }
      .onAppear {
        viewModel.client = client
        if !viewModel.isCompact, viewModel.embeddedStatus == nil {
          Task {
            await viewModel.loadEmbeddedStatus()
          }
        }
        if preferences.serverPreferences?.autoExpandSpoilers == true {
          viewModel.displaySpoiler = false
        }
      }
      .contextMenu {
        StatusRowContextMenu(viewModel: viewModel)
      }
      .background {
        Color.clear
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.navigateToDetail(routerPath: routerPath)
          }
      }
    }
  }

  private func makeFilterView(filter: Filter) -> some View {
    HStack {
      Text("Filtered by: \(filter.title)")
      Button {
        withAnimation {
          viewModel.isFiltered = false
        }
      } label: {
        Text("Show anyway")
      }
    }
  }

  @ViewBuilder
  private var reblogView: some View {
    if viewModel.status.reblog != nil {
      HStack(spacing: 2) {
        Image(systemName: "arrow.left.arrow.right.circle.fill")
        AvatarView(url: viewModel.status.account.avatar, size: .boost)
        if viewModel.status.account.username != account.account?.username {
          EmojiTextApp(viewModel.status.account.safeDisplayName.asMarkdown, emojis: viewModel.status.account.emojis)
          Text("boosted")
        } else {
          Text("You boosted")
        }
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        if viewModel.isRemote, let url = viewModel.status.account.url {
          Task {
            await routerPath.navigateToAccountFrom(url: url)
          }
        } else {
          routerPath.navigate(to: .accountDetailWithAccount(account: viewModel.status.account))
        }
      }
    }
  }

  @ViewBuilder
  var replyView: some View {
    if let accountId = viewModel.status.inReplyToAccountId,
       let mention = viewModel.status.mentions.first(where: { $0.id == accountId })
    {
      HStack(spacing: 2) {
        Image(systemName: "arrowshape.turn.up.left.fill")
        Text("Replied to")
        Text(mention.username)
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        if viewModel.isRemote {
          Task {
            await routerPath.navigateToAccountFrom(url: mention.url)
          }
        } else {
          routerPath.navigate(to: .accountDetail(id: mention.id))
        }
      }
    }
  }

  private var statusView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
        if !viewModel.isCompact {
          HStack(alignment: .top) {
            Button {
              if viewModel.isRemote, let url = status.account.url {
                Task {
                  await routerPath.navigateToAccountFrom(url: url)
                }
              } else {
                routerPath.navigate(to: .accountDetailWithAccount(account: status.account))
              }
            } label: {
              accountView(status: status)
            }.buttonStyle(.plain)
            Spacer()
            menuButton
          }
        }
        makeStatusContentView(status: status)
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.navigateToDetail(routerPath: routerPath)
          }
      }
    }
  }

  private func makeStatusContentView(status: AnyStatus) -> some View {
    Group {
      if !status.spoilerText.isEmpty {
        EmojiTextApp(status.spoilerText.asMarkdown, emojis: status.emojis)
          .font(.body)
        Button {
          withAnimation {
            viewModel.displaySpoiler.toggle()
          }
        } label: {
          Text(viewModel.displaySpoiler ? "Show more" : "Show less")
        }
        .buttonStyle(.bordered)
      }
      if !viewModel.displaySpoiler {
        HStack {
          EmojiTextApp(status.content.asMarkdown, emojis: status.emojis)
            .font(.body)
            .environment(\.openURL, OpenURLAction { url in
              routerPath.handleStatus(status: status, url: url)
            })
          Spacer()
        }

        if !reasons.contains(.placeholder) {
          if !viewModel.isCompact, !viewModel.isEmbedLoading, let embed = viewModel.embeddedStatus {
            StatusEmbeddedView(status: embed)
          } else if viewModel.isEmbedLoading, !viewModel.isCompact {
            StatusEmbeddedView(status: .placeholder())
              .redacted(reason: .placeholder)
              .shimmering()
          }
        }

        if let poll = status.poll {
          StatusPollView(poll: poll)
        }

        if !status.mediaAttachments.isEmpty {
          if theme.statusDisplayStyle == .compact {
            HStack {
              StatusMediaPreviewView(attachments: status.mediaAttachments,
                                     sensitive: status.sensitive,
                                     isNotifications: viewModel.isCompact)
              Spacer()
            }
            .padding(.vertical, 4)
          } else {
            StatusMediaPreviewView(attachments: status.mediaAttachments,
                                   sensitive: status.sensitive,
                                   isNotifications: viewModel.isCompact)
              .padding(.vertical, 4)
          }
        }
        if let card = status.card,
           viewModel.embeddedStatus?.url != status.card?.url,
           status.mediaAttachments.isEmpty,
           !viewModel.isEmbedLoading,
           theme.statusDisplayStyle == .large
        {
          StatusCardView(card: card)
        }
      }
    }
  }

  @ViewBuilder
  private func accountView(status: AnyStatus) -> some View {
    HStack(alignment: .center) {
      if theme.avatarPosition == .top {
        AvatarView(url: status.account.avatar, size: .status)
      }
      VStack(alignment: .leading, spacing: 0) {
        EmojiTextApp(status.account.safeDisplayName.asMarkdown, emojis: status.account.emojis)
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
      StatusRowContextMenu(viewModel: viewModel)
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 30, height: 30)
    }
    .foregroundColor(.gray)
    .contentShape(Rectangle())
  }
}
