import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
struct StatusRowActionsView: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(StatusDataController.self) private var statusDataController
  @Environment(UserPreferences.self) private var userPreferences

  @Environment(\.openWindow) private var openWindow
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @State private var showTextForSelection: Bool = false

  @Binding var isBlockConfirmationPresented: Bool

  var viewModel: StatusRowViewModel

  var isNarrow: Bool {
    horizontalSizeClass == .compact && (UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac)
  }

  func privateBoost() -> Bool {
    viewModel.status.visibility == .priv && viewModel.status.account.id == currentAccount.account?.id
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
    case respond, boost, favorite, bookmark, share, menu

    func image(dataController: StatusDataController, privateBoost: Bool = false) -> Image {
      switch self {
      case .respond:
        return Image(systemName: "arrowshape.turn.up.left")
      case .boost:
        if privateBoost {
          if dataController.isReblogged {
            return Image("Rocket.Fill")
          } else {
            return Image(systemName: "lock.rotation")
          }
        }
        return Image(dataController.isReblogged ? "Rocket.Fill" : "Rocket")
      case .favorite:
        return Image(systemName: dataController.isFavorited ? "star.fill" : "star")
      case .bookmark:
        return Image(systemName: dataController.isBookmarked ? "bookmark.fill" : "bookmark")
      case .share:
        return Image(systemName: "square.and.arrow.up")
      case .menu:
        return Image(systemName: "ellipsis")
      }
    }

    func accessibilityLabel(dataController: StatusDataController, privateBoost: Bool = false) -> LocalizedStringKey {
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
      case .boost:
        return dataController.reblogsCount
      case .share, .bookmark, .menu:
        return nil
      }
    }

    func tintColor(theme: Theme) -> Color? {
      switch self {
      case .respond, .share, .menu:
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
      case .respond, .share, .menu: false
      case .favorite: dataController.isFavorited
      case .bookmark: dataController.isBookmarked
      case .boost: dataController.isReblogged
      }
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        ForEach(actions, id: \.self) { action in
          if action == .share {
            if let urlString = viewModel.finalStatus.url,
               let url = URL(string: urlString)
            {
              switch userPreferences.shareButtonBehavior {
              case .linkOnly:
                ShareLink(item: url) {
                  action.image(dataController: statusDataController)
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
                .buttonStyle(.borderless)
                #if !os(visionOS)
                  .offset(x: -8)
                #endif
                  .accessibilityElement(children: .combine)
                  .accessibilityLabel("status.action.share-link")
              case .linkAndText:
                ShareLink(item: url,
                          subject: Text(viewModel.finalStatus.account.safeDisplayName),
                          message: Text(viewModel.finalStatus.content.asRawText))
                {
                  action.image(dataController: statusDataController)
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
                .buttonStyle(.borderless)
                #if !os(visionOS)
                  .offset(x: -8)
                #endif
                  .accessibilityElement(children: .combine)
                  .accessibilityLabel("status.action.share-link")
              }
            }
            Spacer()
          } else if action == .menu {
            Menu {
              StatusRowContextMenu(viewModel: viewModel,
                                   showTextForSelection: $showTextForSelection,
                                   isBlockConfirmationPresented: $isBlockConfirmationPresented)
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
            .contentShape(Rectangle())
            .accessibilityLabel("status.action.context-menu")
          } else {
            actionButton(action: action)
            Spacer()
          }
        }
      }
    }
    .sheet(isPresented: $showTextForSelection) {
      let content = viewModel.status.reblog?.content.asSafeMarkdownAttributedString ?? viewModel.status.content.asSafeMarkdownAttributedString
      SelectTextView(content: content)
    }
  }

  private func actionButton(action: Action) -> some View {
    Button {
      handleAction(action: action)
    } label: {
      HStack(spacing: 2) {
        if action == .boost {
          action
            .image(dataController: statusDataController, privateBoost: privateBoost())
            .imageScale(.medium)
            .fontWeight(.black)
          #if targetEnvironment(macCatalyst)
            .font(.scaledBody)
          #else
            .font(.body)
            .dynamicTypeSize(.large)
          #endif
        } else {
          action
            .image(dataController: statusDataController, privateBoost: privateBoost())
          #if targetEnvironment(macCatalyst)
            .font(.scaledBody)
          #else
            .font(.body)
            .dynamicTypeSize(.large)
          #endif
        }
        if !isNarrow,
           let count = action.count(dataController: statusDataController,
                                    isFocused: isFocused,
                                    theme: theme), !viewModel.isRemote
        {
          Text(count, format: .number.notation(.compactName))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .contentTransition(.numericText(value: Double(count)))
            .foregroundColor(Color(UIColor.secondaryLabel))
          #if targetEnvironment(macCatalyst)
            .font(.scaledFootnote)
          #else
            .font(.footnote)
            .dynamicTypeSize(.medium)
          #endif
            .monospacedDigit()
            .opacity(count > 0 ? 1 : 0)
        }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .contentShape(Rectangle())
    }
    #if os(visionOS)
    .buttonStyle(.borderless)
    .foregroundColor(Color(UIColor.secondaryLabel))
    #else
    .buttonStyle(
      .statusAction(
        isOn: action.isOn(dataController: statusDataController),
        tintColor: action.tintColor(theme: theme)
      )
    )
    .offset(x: -8)
    #endif
    .disabled(action == .boost &&
      (viewModel.status.visibility == .direct || viewModel.status.visibility == .priv && viewModel.status.account.id != currentAccount.account?.id))
    .accessibilityElement(children: .combine)
    .accessibilityLabel(action.accessibilityLabel(dataController: statusDataController, privateBoost: privateBoost()))
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
          openWindow(value: WindowDestinationEditor.replyToStatusEditor(status: viewModel.localStatus ?? viewModel.status))
        #else
          viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.localStatus ?? viewModel.status)
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
      default:
        break
      }
    }
  }
}
