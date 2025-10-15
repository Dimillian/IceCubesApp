import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct StatusRowActionsView: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(StatusDataController.self) private var statusDataController
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(MastodonClient.self) private var client
  @Environment(SceneDelegate.self) private var sceneDelegate

  @Environment(\.openWindow) private var openWindow
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @State private var showTextForSelection: Bool = false
  @State private var isShareAsImageSheetPresented: Bool = false

  @Binding var isBlockConfirmationPresented: Bool

  struct ActionButtonConfiguration {
    let display: Action
    let trigger: Action
    let showsMenu: Bool
  }

  var viewModel: StatusRowViewModel

  var isNarrow: Bool {
    horizontalSizeClass == .compact
      && (UIDevice.current.userInterfaceIdiom == .pad
        || UIDevice.current.userInterfaceIdiom == .mac)
  }

  func privateBoost() -> Bool {
    viewModel.status.visibility == .priv
      && viewModel.status.account.id == currentAccount.account?.id
  }

  var actions: [Action] {
    switch theme.statusActionSecondary {
    case .share:
      return [.respond, .boost, .favorite, .share, .menu]
    case .bookmark:
      return [.respond, .boost, .favorite, .bookmark, .menu]
    }
  }

  @MainActor
  enum Action {
    case respond, boost, quote, favorite, bookmark, share, menu

    func image(dataController: StatusDataController, privateBoost: Bool = false) -> Image {
      switch self {
      case .respond:
        return Image(systemName: "arrowshape.turn.up.left")
      case .boost:
        if privateBoost {
          if dataController.isReblogged {
            return Image(systemName: "arrow.2.squarepath")
          } else {
            return Image(systemName: "lock.rotation")
          }
        }
        return Image(systemName: "arrow.2.squarepath")
      case .favorite:
        return Image(systemName: dataController.isFavorited ? "star.fill" : "star")
      case .bookmark:
        return Image(systemName: dataController.isBookmarked ? "bookmark.fill" : "bookmark")
      case .share:
        return Image(systemName: "square.and.arrow.up")
      case .quote:
        return Image(systemName: "quote.bubble")
      case .menu:
        return Image(systemName: "ellipsis")
      }
    }

    func accessibilityLabel(dataController: StatusDataController, privateBoost: Bool = false)
      -> LocalizedStringKey
    {
      switch self {
      case .respond:
        return "status.action.reply"
      case .boost:
        if dataController.isReblogged {
          return "status.action.unboost"
        }
        return privateBoost
          ? "status.action.boost-to-followers"
          : "status.action.boost"
      case .favorite:
        return dataController.isFavorited
          ? "status.action.unfavorite"
          : "status.action.favorite"
      case .bookmark:
        return dataController.isBookmarked
          ? "status.action.unbookmark"
          : "status.action.bookmark"
      case .share:
        return "status.action.share"
      case .menu:
        return "status.context.menu"
      case .quote:
        return "Quote"
      }
    }

    func count(dataController: StatusDataController, isFocused: Bool, theme: Theme) -> Int? {
      if theme.statusActionsDisplay == .discret, !isFocused {
        return nil
      }
      switch self {
      case .respond:
        return dataController.repliesCount
      case .favorite:
        return dataController.favoritesCount
      case .boost, .quote:
        return dataController.reblogsCount + dataController.quotesCount
      case .share, .bookmark, .menu:
        return nil
      }
    }

    func tintColor(theme: Theme) -> Color? {
      switch self {
      case .respond, .share, .menu, .quote:
        nil
      case .favorite:
        .yellow
      case .bookmark:
        .pink
      case .boost:
        theme.tintColor
      }
    }

    func isOn(dataController: StatusDataController) -> Bool {
      switch self {
      case .respond, .share, .menu, .quote: false
      case .favorite: dataController.isFavorited
      case .bookmark: dataController.isBookmarked
      case .boost: dataController.isReblogged
      }
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      actionsRow
    }
    .fixedSize(horizontal: false, vertical: true)
    .sheet(isPresented: $showTextForSelection, content: makeSelectableTextSheet)
    .sheet(isPresented: $isShareAsImageSheetPresented, content: makeShareAsImageSheet)
  }

  private var actionsRow: some View {
    HStack {
      ForEach(actions, id: \.self) { action in
        actionView(for: action)
      }
    }
  }

  @ViewBuilder
  private func actionView(for action: Action) -> some View {
    switch action {
    case .share:
      shareActionView(for: action)
    case .menu:
      menuActionView()
    default:
      actionButton(action: action)
    }
  }

  @ViewBuilder
  private func shareActionView(for action: Action) -> some View {
    if let urlString = viewModel.finalStatus.url,
      let url = URL(string: urlString)
    {
      HStack {
        shareLink(for: url, action: action)
        Spacer()
      }
    } else {
      EmptyView()
    }
  }

  @ViewBuilder
  private func menuActionView() -> some View {
    Menu {
      StatusRowContextMenu(
        viewModel: viewModel,
        showTextForSelection: $showTextForSelection,
        isBlockConfirmationPresented: $isBlockConfirmationPresented,
        isShareAsImageSheetPresented: $isShareAsImageSheetPresented
      )
      .onAppear {
        Task {
          await viewModel.loadAuthorRelationship()
        }
      }
    } label: {
      Label("", systemImage: "ellipsis")
        .padding(.vertical, 6)
    }
    .menuStyle(.button)
    .buttonStyle(.borderless)
    .foregroundStyle(.secondary)
    .tint(.primary)
    .contentShape(Rectangle())
    .accessibilityLabel("status.action.context-menu")
  }

  @ViewBuilder
  private func shareLink(for url: URL, action: Action) -> some View {
    switch userPreferences.shareButtonBehavior {
    case .linkOnly:
      shareLinkView(
        ShareLink(item: url) {
          shareButtonLabel(for: action)
        }
      )
    case .linkAndText:
      shareLinkView(
        ShareLink(
          item: url,
          subject: Text(viewModel.finalStatus.account.safeDisplayName),
          message: Text(viewModel.finalStatus.content.asRawText)
        ) {
          shareButtonLabel(for: action)
        }
      )
    }
  }

  @ViewBuilder
  private func shareLinkView<V: View>(_ view: V) -> some View {
    view
      .buttonStyle(.borderless)
      #if !os(visionOS)
        .offset(x: -8)
      #endif
      .accessibilityElement(children: .combine)
      .accessibilityLabel("status.action.share-link")
  }

  private func shareButtonLabel(for action: Action) -> some View {
    action
      .image(dataController: statusDataController)
      .foregroundColor(Color(UIColor.secondaryLabel))
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .contentShape(Rectangle())
      #if targetEnvironment(macCatalyst)
        .font(.scaledBody)
      #else
        .font(.body)
        .dynamicTypeSize(.large)
      #endif
  }

  private func makeSelectableTextSheet() -> some View {
    let content =
      viewModel.status.reblog?.content.asSafeMarkdownAttributedString
      ?? viewModel.status.content.asSafeMarkdownAttributedString
    return StatusRowSelectableTextView(content: content)
      .tint(theme.tintColor)
  }

  private func makeShareAsImageSheet() -> some View {
    let renderer = ImageRenderer(content: AnyView(shareCaptureView))
    renderer.isOpaque = true
    renderer.scale = 3.0
    return StatusRowShareAsImageView(
      viewModel: viewModel,
      renderer: renderer
    )
    .tint(theme.tintColor)
  }

  private var shareCaptureView: some View {
    HStack {
      StatusRowView(viewModel: viewModel, context: .timeline)
        .padding(8)
    }
    .environment(\.isInCaptureMode, true)
    .environment(RouterPath())
    .environment(QuickLook.shared)
    .environment(theme)
    .environment(client)
    .environment(sceneDelegate)
    .environment(UserPreferences.shared)
    .environment(CurrentAccount.shared)
    .environment(CurrentInstance.shared)
    .environment(statusDataController)
    .preferredColorScheme(theme.selectedScheme == .dark ? .dark : .light)
    .foregroundColor(theme.labelColor)
    .background(theme.primaryBackgroundColor)
    .frame(width: sceneDelegate.windowWidth - 12)
    .tint(theme.tintColor)
  }

  @ViewBuilder
  private func actionButton(action: Action) -> some View {
    let configuration = configuration(for: action)
    let finalStatus = viewModel.finalStatus
    let isQuoteUnavailable =
      (finalStatus.visibility == .priv || finalStatus.visibility == .direct)
      || finalStatus.quoteApproval?.currentUser == .denied
    let shouldDisableAction =
      (configuration.trigger == .boost
        && (finalStatus.visibility == .priv || finalStatus.visibility == .direct))
      || (configuration.trigger == .quote && isQuoteUnavailable)

    StatusActionButton(
      configuration: configuration,
      statusDataController: statusDataController,
      status: viewModel.status,
      quoteStatus: finalStatus,
      theme: theme,
      isFocused: isFocused,
      isNarrow: isNarrow,
      isRemoteStatus: viewModel.isRemote,
      privateBoost: privateBoost(),
      isDisabled: shouldDisableAction,
      handleAction: handleAction(action:)
    )
  }

  private func configuration(for action: Action) -> ActionButtonConfiguration {
    guard action == .boost else {
      return .init(display: action, trigger: action, showsMenu: false)
    }

    switch userPreferences.boostButtonBehavior {
    case .both:
      return .init(display: .boost, trigger: .boost, showsMenu: true)
    case .boostOnly:
      return .init(display: .boost, trigger: .boost, showsMenu: false)
    case .quoteOnly:
      return .init(display: .quote, trigger: .quote, showsMenu: false)
    }
  }

  private func handleAction(action: Action) {
    Task {
      if viewModel.isRemote, viewModel.localStatusId == nil || viewModel.localStatus == nil {
        guard await viewModel.fetchRemoteStatus() else {
          return
        }
      }
      HapticManager.shared.fireHaptic(.notification(.success))
      switch action {
      case .respond:
        SoundEffectManager.shared.playSound(.share)
        #if targetEnvironment(macCatalyst) || os(visionOS)
          openWindow(
            value: WindowDestinationEditor.replyToStatusEditor(
              status: viewModel.localStatus ?? viewModel.status))
        #else
          viewModel.routerPath.presentedSheet = .replyToStatusEditor(
            status: viewModel.localStatus ?? viewModel.status)
        #endif
      case .favorite:
        SoundEffectManager.shared.playSound(.favorite)
        await statusDataController.toggleFavorite(remoteStatus: viewModel.localStatusId)
      case .bookmark:
        SoundEffectManager.shared.playSound(.bookmark)
        await statusDataController.toggleBookmark(remoteStatus: viewModel.localStatusId)
      case .boost:
        SoundEffectManager.shared.playSound(.boost)
        await statusDataController.toggleReblog(remoteStatus: viewModel.localStatusId)
      case .quote:
        SoundEffectManager.shared.playSound(.boost)
        #if targetEnvironment(macCatalyst) || os(visionOS)
          openWindow(value: WindowDestinationEditor.quoteStatusEditor(status: viewModel.status))
        #else
          viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
        #endif
      default:
        break
      }
    }
  }
}
