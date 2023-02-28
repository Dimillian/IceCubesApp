import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct StatusRowActionsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var statusDataController: StatusDataController
  @ObservedObject var viewModel: StatusRowViewModel

  func privateBoost() -> Bool {
    return viewModel.status.visibility == .priv && viewModel.status.account.id == currentAccount.account?.id
  }

  @MainActor
  enum Action: CaseIterable {
    case respond, boost, favorite, bookmark, share

    // Have to implement this manually here due to compiler not implicitly
    // inserting `nonisolated`, which leads to a warning:
    //
    //     Main actor-isolated static property 'allCases' cannot be used to
    //     satisfy nonisolated protocol requirement
    //
    nonisolated public static var allCases: [StatusRowActionsView.Action] {
      [.respond, .boost, .favorite, .bookmark, .share]
    }

    func iconName(dataController: StatusDataController, privateBoost: Bool = false) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
        if privateBoost {
          return dataController.isReblogged ? "Rocket.Fill" : "Rocket"
        }
        return dataController.isReblogged ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
      case .favorite:
        return dataController.isFavorited ? "star.fill" : "star"
      case .bookmark:
        return dataController.isBookmarked ? "bookmark.fill" : "bookmark"
      case .share:
        return "square.and.arrow.up"
      }
    }

    func count(dataController: StatusDataController, viewModel: StatusRowViewModel, theme: Theme) -> Int? {
      if theme.statusActionsDisplay == .discret && !viewModel.isFocused {
        return nil
      }
      switch self {
      case .respond:
        return dataController.repliesCount
      case .favorite:
        return dataController.favoritesCount
      case .boost:
        return dataController.reblogsCount
      case .share, .bookmark:
        return nil
      }
    }

    func tintColor(theme: Theme) -> Color? {
      switch self {
      case .respond, .share:
        return nil
      case .favorite:
        return .yellow
      case .bookmark:
        return .pink
      case .boost:
        return theme.tintColor
      }
    }

    func isOn(dataController: StatusDataController) -> Bool {
      switch self {
      case .respond, .share: return false
      case .favorite: return dataController.isFavorited
      case .bookmark: return dataController.isBookmarked
      case .boost: return dataController.isReblogged
      }
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        ForEach(Action.allCases, id: \.self) { action in
          if action == .share {
            if let urlString = viewModel.status.reblog?.url ?? viewModel.status.url,
               let url = URL(string: urlString)
            {
              ShareLink(item: url,
                        subject: Text(viewModel.status.reblog?.account.safeDisplayName ?? viewModel.status.account.safeDisplayName),
                        message: Text(viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText)) {
<<<<<<< HEAD
                  Image(imageNamed: action.iconName(viewModel: viewModel))
=======
                Image(systemName: action.iconName(dataController: statusDataController))
>>>>>>> main
              }
              .buttonStyle(.statusAction())
            }
          } else {
            actionButton(action: action)
            Spacer()
          }
        }
      }
      if viewModel.isFocused {
        StatusRowDetailView(viewModel: viewModel)
      }
    }
  }

  private func actionButton(action: Action) -> some View {
    HStack(spacing: 2) {
      Button {
        handleAction(action: action)
      } label: {
<<<<<<< HEAD
        Image(imageNamed: action.iconName(viewModel: viewModel, privateBoost: privateBoost()))
=======
        Image(systemName: action.iconName(dataController: statusDataController, privateBoost: privateBoost()))
>>>>>>> main
      }
      .buttonStyle(
        .statusAction(
          isOn: action.isOn(dataController: statusDataController),
          tintColor: action.tintColor(theme: theme)
        )
      )
      .disabled(action == .boost &&
        (viewModel.status.visibility == .direct || viewModel.status.visibility == .priv && viewModel.status.account.id != currentAccount.account?.id))
      if let count = action.count(dataController: statusDataController,
                                  viewModel: viewModel,
                                  theme: theme), !viewModel.isRemote {
        Text("\(count)")
          .foregroundColor(Color(UIColor.secondaryLabel))
          .font(.scaledFootnote)
          .monospacedDigit()
      }
    }
  }
    

  private func handleAction(action: Action) {
    Task {
      if viewModel.isRemote, viewModel.localStatusId == nil || viewModel.localStatus == nil {
        guard await viewModel.fetchRemoteStatus() else {
          return
        }
      }
      HapticManager.shared.fireHaptic(of: .notification(.success))
      switch action {
      case .respond:
        viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.localStatus ?? viewModel.status)
      case .favorite:
        await statusDataController.toggleFavorite()
      case .bookmark:
        await statusDataController.toggleBookmark()
      case .boost:
        await statusDataController.toggleReblog()
      default:
        break
      }
    }
  }
}
