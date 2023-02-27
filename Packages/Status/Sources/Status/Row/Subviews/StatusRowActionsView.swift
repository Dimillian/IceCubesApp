import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct StatusRowActionsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @ObservedObject var viewModel: StatusRowViewModel

  func privateBoost() -> Bool {
    return viewModel.status.visibility == .priv && viewModel.status.account.id == currentAccount.account?.id
  }

  @MainActor
  enum Action: CaseIterable {
    case respond, boost, favorite, bookmark, share

    func iconName(viewModel: StatusRowViewModel, privateBoost: Bool = false) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
        if privateBoost {
          return viewModel.isReblogged ? "Rocket.Fill" : "lock.rotation"
        }

        return viewModel.isReblogged ? "Rocket.Fill" : "Rocket"
      case .favorite:
        return viewModel.isFavorited ? "star.fill" : "star"
      case .bookmark:
        return viewModel.isBookmarked ? "bookmark.fill" : "bookmark"
      case .share:
        return "square.and.arrow.up"
      }
    }

    func count(viewModel: StatusRowViewModel, theme: Theme) -> Int? {
      if theme.statusActionsDisplay == .discret && !viewModel.isFocused {
        return nil
      }
      switch self {
      case .respond:
        return viewModel.repliesCount
      case .favorite:
        return viewModel.favoritesCount
      case .boost:
        return viewModel.reblogsCount
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

    func isOn(viewModel: StatusRowViewModel) -> Bool {
      switch self {
      case .respond, .share: return false
      case .favorite: return viewModel.isFavorited
      case .bookmark: return viewModel.isBookmarked
      case .boost: return viewModel.isReblogged
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
                  Image(imageNamed: action.iconName(viewModel: viewModel))
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
        Image(imageNamed: action.iconName(viewModel: viewModel, privateBoost: privateBoost()))
      }
      .buttonStyle(
        .statusAction(
          isOn: action.isOn(viewModel: viewModel),
          tintColor: action.tintColor(theme: theme)
        )
      )
      .disabled(action == .boost &&
        (viewModel.status.visibility == .direct || viewModel.status.visibility == .priv && viewModel.status.account.id != currentAccount.account?.id))
      if let count = action.count(viewModel: viewModel, theme: theme), !viewModel.isRemote {
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
        if viewModel.isFavorited {
          await viewModel.unFavorite()
        } else {
          await viewModel.favorite()
        }
      case .bookmark:
        if viewModel.isBookmarked {
          await viewModel.unbookmark()
        } else {
          await viewModel.bookmark()
        }
      case .boost:
        if viewModel.isReblogged {
          await viewModel.unReblog()
        } else {
          await viewModel.reblog()
        }
      default:
        break
      }
    }
  }
}
