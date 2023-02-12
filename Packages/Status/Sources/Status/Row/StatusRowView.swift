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
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  @StateObject var viewModel: StatusRowViewModel

  public init(viewModel: StatusRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var contextMenu: some View {
    StatusRowContextMenu(viewModel: viewModel)
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
      VStack(alignment: .leading) {
        if !viewModel.isCompact, theme.avatarPosition == .leading {
          reblogView
          replyView
        }
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
            if !viewModel.isCompact, theme.avatarPosition == .top {
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
      }
      .onAppear {
        viewModel.markSeen()
        if reasons.isEmpty {
          viewModel.client = client
          if !viewModel.isCompact, viewModel.embeddedStatus == nil {
            Task {
              await viewModel.loadEmbeddedStatus()
            }
          }
          if preferences.autoExpandSpoilers == true && viewModel.displaySpoiler {
            viewModel.displaySpoiler = false
          }
        }
      }
      .contextMenu {
        contextMenu
      }
      .listRowBackground(viewModel.highlightRowColor)
      .swipeActions(edge: .trailing) {
        if !viewModel.isCompact {
          trailingSwipeActions
        }
      }
      .swipeActions(edge: .leading) {
        if !viewModel.isCompact {
          leadingSwipeActions
        }
      }
      .listRowInsets(.init(top: 12,
                           leading: .layoutPadding,
                           bottom: 12,
                           trailing: .layoutPadding))
      .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
      .accessibilityActions {
        accesibilityActions
      }
      .background {
        Color.clear
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.navigateToDetail(routerPath: routerPath)
          }
      }
      .overlay {
        if viewModel.isLoadingRemoteContent {
          remoteContentLoadingView
        }
      }
      .alert(isPresented: $viewModel.showDeleteAlert, content: {
        Alert(
          title: Text("status.action.delete.confirm.title"),
          message: Text("status.action.delete.confirm.message"),
          primaryButton: .destructive(
            Text("status.action.delete"))
          {
            Task {
              await viewModel.delete()
            }
          },
          secondaryButton: .cancel()
        )
      })
      .alignmentGuide(.listRowSeparatorLeading) { _ in
        -100
      }
    }
  }

  @ViewBuilder
  private var accesibilityActions: some View {
    // Add the individual mentions as accessibility actions
    ForEach(viewModel.status.mentions, id: \.id) { mention in
      Button("@\(mention.username)") {
        routerPath.navigate(to: .accountDetail(id: mention.id))
      }
    }

    Button(viewModel.displaySpoiler ? "status.show-more" : "status.show-less") {
      withAnimation {
        viewModel.displaySpoiler.toggle()
      }
    }

    Button("@\(viewModel.status.account.username)") {
      routerPath.navigate(to: .accountDetail(id: viewModel.status.account.id))
    }

    contextMenu
  }

  private func makeFilterView(filter: Filter) -> some View {
    HStack {
      Text("status.filter.filtered-by-\(filter.title)")
      Button {
        withAnimation {
          viewModel.isFiltered = false
        }
      } label: {
        Text("status.filter.show-anyway")
      }
    }
  }

  @ViewBuilder
  private var reblogView: some View {
    if viewModel.status.reblog != nil {
      HStack(spacing: 2) {
        Image(systemName: "arrow.left.arrow.right.circle.fill")
        AvatarView(url: viewModel.status.account.avatar, size: .boost)
        EmojiTextApp(.init(stringValue: viewModel.status.account.safeDisplayName), emojis: viewModel.status.account.emojis)
        Text("status.row.was-boosted")
      }
      .accessibilityElement()
      .accessibilityLabel(
        Text("\(viewModel.status.account.safeDisplayName)")
          + Text(" ")
          + Text("status.row.was-boosted")
      )
      .font(.scaledFootnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        viewModel.navigateToAccountDetail(account: viewModel.status.account, routerPath: routerPath)
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
        Text("status.row.was-reply")
        Text(mention.username)
      }
      .font(.scaledFootnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
      .onTapGesture {
        viewModel.navigateToMention(mention: mention, routerPath: routerPath)
      }
    }
  }

  private var statusView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
        if !viewModel.isCompact {
          HStack(alignment: .center) {
            Button {
              viewModel.navigateToAccountDetail(account: status.account, routerPath: routerPath)
            } label: {
              accountView(status: status)
            }
            .buttonStyle(.plain)
            Spacer()
            threadIcon
            contextMenuButton
          }
          .accessibilityElement()
          .accessibilityLabel(Text("\(status.account.displayName)"))
        }
        makeStatusContentView(status: status)
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.navigateToDetail(routerPath: routerPath)
          }
      }
    }
    .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
    .accessibilityAction {
      viewModel.navigateToDetail(routerPath: routerPath)
    }
  }

  private func makeStatusContentView(status: AnyStatus) -> some View {
    Group {
      if !status.spoilerText.asRawText.isEmpty {
        HStack(alignment: .top) {
          Text("⚠︎")
            .font(.system(.subheadline, weight: .bold))
            .foregroundColor(.secondary)
          EmojiTextApp(status.spoilerText, emojis: status.emojis, language: status.language)
            .font(.system(.subheadline, weight: .bold))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
          Spacer()
          Button {
            withAnimation {
              viewModel.displaySpoiler.toggle()
            }
          } label: {
            Image(systemName: "chevron.down")
              .rotationEffect(Angle(degrees: viewModel.displaySpoiler ? 0 : 180))
          }
          .buttonStyle(.bordered)
          .accessibility(label: viewModel.displaySpoiler ? Text("status.show-more") : Text("status.show-less"))
          .accessibilityHidden(true)
        }
        .onTapGesture { // make whole row tapable to make up for smaller button size
          withAnimation {
            viewModel.displaySpoiler.toggle()
          }
        }
      }

      if !viewModel.displaySpoiler {
        HStack {
          EmojiTextApp(status.content, emojis: status.emojis, language: status.language)
            .font(.scaledBody)
            .environment(\.openURL, OpenURLAction { url in
              routerPath.handleStatus(status: status, url: url)
            })
          Spacer()
        }

        makeTranslateView(status: status)

        if let poll = status.poll {
          StatusPollView(poll: poll, status: status)
        }

        embedStatusView

        makeMediasView(status: status)
          .accessibilityHidden(!viewModel.isFocused)
        makeCardView(status: status)
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
        EmojiTextApp(.init(stringValue: status.account.safeDisplayName), emojis: status.account.emojis)
          .font(.scaledSubheadline)
          .fontWeight(.semibold)
        Group {
          Text("@\(status.account.acct)") +
            Text(" ⸱ ") +
            Text(status.createdAt.relativeFormatted) +
            Text(" ⸱ ") +
            Text(Image(systemName: viewModel.status.visibility.iconName))
        }
        .font(.scaledFootnote)
        .foregroundColor(.gray)
      }
    }
  }

  @ViewBuilder
  private var threadIcon: some View {
    if viewModel.status.reblog?.inReplyToAccountId != nil || viewModel.status.inReplyToAccountId != nil {
      Image(systemName: "bubble.left.and.bubble.right")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 15)
        .foregroundColor(.gray)
    }
  }

  private var contextMenuButton: some View {
    Menu {
      contextMenu
    } label: {
      Image(systemName: "ellipsis")
        .frame(width: 20, height: 30)
    }
    .menuStyle(.borderlessButton)
    .foregroundColor(.gray)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }

  private func shouldShowTranslateButton(status: AnyStatus) -> Bool {
    let statusLang = viewModel.getStatusLang()

    if let userLang = preferences.serverPreferences?.postLanguage,
       preferences.showTranslateButton,
       !status.content.asRawText.isEmpty,
       viewModel.translation == nil
    {
      return userLang != statusLang
    } else {
      return false
    }
  }

  @ViewBuilder
  private func makeTranslateView(status: AnyStatus) -> some View {
    if let userLang = preferences.serverPreferences?.postLanguage,
       shouldShowTranslateButton(status: status)
    {
      Button {
        Task {
          await viewModel.translate(userLang: userLang)
        }
      } label: {
        if viewModel.isLoadingTranslation {
          ProgressView()
        } else {
          if let statusLanguage = viewModel.getStatusLang(),
             let languageName = Locale.current.localizedString(forLanguageCode: statusLanguage)
          {
            Text("status.action.translate-from-\(languageName)")
          } else {
            Text("status.action.translate")
          }
        }
      }
      .buttonStyle(.borderless)
    }

    if let translation = viewModel.translation, !viewModel.isLoadingTranslation {
      GroupBox {
        VStack(alignment: .leading, spacing: 4) {
          Text(translation.content.asSafeMarkdownAttributedString)
            .font(.scaledBody)
          Text("status.action.translated-label-\(translation.provider)")
            .font(.footnote)
            .foregroundColor(.gray)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private func makeMediasView(status: AnyStatus) -> some View {
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
  }

  @ViewBuilder
  private func makeCardView(status: AnyStatus) -> some View {
    if let card = status.card,
       !viewModel.isEmbedLoading,
       !viewModel.isCompact,
       theme.statusDisplayStyle == .large,
       status.content.statusesURLs.isEmpty,
       status.mediaAttachments.isEmpty
    {
      StatusCardView(card: card)
    }
  }

  @ViewBuilder
  private var embedStatusView: some View {
    if !reasons.contains(.placeholder) {
      if !viewModel.isCompact, !viewModel.isEmbedLoading,
         let embed = viewModel.embeddedStatus
      {
        StatusEmbeddedView(status: embed)
          .fixedSize(horizontal: false, vertical: true)
      } else if viewModel.isEmbedLoading, !viewModel.isCompact {
        StatusEmbeddedView(status: .placeholder())
          .redacted(reason: .placeholder)
          .shimmering()
      }
    }
  }

  private var remoteContentLoadingView: some View {
    ZStack(alignment: .center) {
      VStack {
        Spacer()
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        Spacer()
      }
    }
    .background(Color.black.opacity(0.40))
    .transition(.opacity)
  }

  @ViewBuilder
  private var trailingSwipeActions: some View {
    if preferences.swipeActionsStatusTrailingRight != StatusAction.none {
      makeSwipeButton(action: preferences.swipeActionsStatusTrailingRight)
    }
    if preferences.swipeActionsStatusTrailingLeft != StatusAction.none {
      makeSwipeButton(action: preferences.swipeActionsStatusTrailingLeft)
    }
  }

  @ViewBuilder
  private var leadingSwipeActions: some View {
    if preferences.swipeActionsStatusLeadingLeft != StatusAction.none {
      makeSwipeButton(action: preferences.swipeActionsStatusLeadingLeft)
    }
    if preferences.swipeActionsStatusLeadingRight != StatusAction.none {
      makeSwipeButton(action: preferences.swipeActionsStatusLeadingRight)
    }
  }

  @ViewBuilder
  private func makeSwipeButton(action: StatusAction) -> some View {
    switch action {
    case .reply:
      makeSwipeButtonForRouterPath(action: action, destination: .replyToStatusEditor(status: viewModel.status))
    case .quote:
      makeSwipeButtonForRouterPath(action: action, destination: .quoteStatusEditor(status: viewModel.status))
    case .favorite:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isFavorited {
          await viewModel.unFavorite()
        } else {
          await viewModel.favorite()
        }
      }
    case .boost:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isReblogged {
          await viewModel.unReblog()
        } else {
          await viewModel.reblog()
        }
      }
    case .bookmark:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isBookmarked {
          await viewModel.unbookmark()
        } else {
          await
            viewModel.bookmark()
        }
      }
    case .none:
      EmptyView()
    }
  }

  @ViewBuilder
  private func makeSwipeButtonForRouterPath(action: StatusAction, destination: SheetDestinations) -> some View {
    Button {
      HapticManager.shared.fireHaptic(of: .notification(.success))
      routerPath.presentedSheet = destination
    } label: {
      Text(action.displayName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
      Image(systemName: action.iconName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
        .environment(\.symbolVariants, .none)
    }
    .tint(action.color(themeTintColor: theme.tintColor))
  }

  @ViewBuilder
  private func makeSwipeButtonForTask(action: StatusAction, task: @escaping () async -> Void) -> some View {
    Button {
      Task {
        HapticManager.shared.fireHaptic(of: .notification(.success))
        await task()
      }
    } label: {
      Text(action.displayName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
      Image(systemName: action.iconName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
        .environment(\.symbolVariants, .none)
    }
    .tint(action.color(themeTintColor: theme.tintColor))
  }
}
