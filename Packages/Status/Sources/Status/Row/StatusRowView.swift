import SwiftUI
import Models
import Env
import DesignSystem
import Network
import Shimmer

public struct StatusRowView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
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
          if !viewModel.isCompact && !viewModel.isRemote, theme.statusActionsDisplay != .none {
            StatusActionsView(viewModel: viewModel)
              .padding(.top, 8)
              .tint(viewModel.isFocused ? theme.tintColor : .gray)
              .contentShape(Rectangle())
              .onTapGesture {
                viewModel.navigateToDetail(routeurPath: routeurPath)
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
        if preferences.serverPreferences?.autoExpandSpoilers == true {
          viewModel.displaySpoiler = false
        }
      }
      .contextMenu {
        StatusRowContextMenu(viewModel: viewModel)
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
        Image(systemName:"arrow.left.arrow.right.circle.fill")
        AvatarView(url: viewModel.status.account.avatar, size: .boost)
        viewModel.status.account.displayNameWithEmojis
        Text("boosted")
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        if viewModel.isRemote, let url = viewModel.status.account.url {
          Task {
            await routeurPath.navigateToAccountFrom(url: url)
          }
        } else {
          routeurPath.navigate(to: .accountDetailWithAccount(account: viewModel.status.account))
        }
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
        if viewModel.isRemote {
          Task {
            await routeurPath.navigateToAccountFrom(url: mention.url)
          }
        } else {
          routeurPath.navigate(to: .accountDetail(id: mention.id))
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
                  await routeurPath.navigateToAccountFrom(url: url)
                }
              } else {
                routeurPath.navigate(to: .accountDetailWithAccount(account: status.account))
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
            viewModel.navigateToDetail(routeurPath: routeurPath)
          }
      }
    }
  }
  
  private func makeStatusContentView(status: AnyStatus) -> some View {
    Group {
      if !status.spoilerText.isEmpty {
        Text(status.spoilerText)
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
          Text(status.content.asSafeAttributedString)
            .font(.body)
            .environment(\.openURL, OpenURLAction { url in
              routeurPath.handleStatus(status: status, url: url)
            })
          Spacer()
        }
        
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
          if theme.statusDisplayStyle == .compact {
            HStack {
              StatusMediaPreviewView(attachements: status.mediaAttachments,
                                     sensitive: status.sensitive,
                                     isNotifications: viewModel.isCompact)
              Spacer()
            }
            .padding(.vertical, 4)
          } else {
            StatusMediaPreviewView(attachements: status.mediaAttachments,
                                   sensitive: status.sensitive,
                                   isNotifications: viewModel.isCompact)
            .padding(.vertical, 4)
          }
        }
        if let card = status.card,
           viewModel.embededStatus?.url != status.card?.url,
           status.mediaAttachments.isEmpty,
           !viewModel.isEmbedLoading,
           theme.statusDisplayStyle == .large {
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
      StatusRowContextMenu(viewModel: viewModel)
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 30, height: 30)
    }
    .foregroundColor(.gray)
    .contentShape(Rectangle())
  }
}
