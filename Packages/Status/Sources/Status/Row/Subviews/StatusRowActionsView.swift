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
    return self.viewModel.status.visibility == .priv && self.viewModel.status.account.id == self.currentAccount.account?.id
  }
  
  @MainActor
  enum Actions: CaseIterable {
    case respond, boost, favorite, bookmark, share

    func iconName(viewModel: StatusRowViewModel, privateBoost: Bool = false) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
        if (privateBoost) {
          return viewModel.isReblogged ? "arrow.left.arrow.right.circle.fill" : "lock.rotation"
        }
        
        return viewModel.isReblogged ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
      case .favorite:
        return viewModel.isFavorited ? "star.fill" : "star"
      case .bookmark:
        return viewModel.isBookmarked ? "bookmark.fill" : "bookmark"
      case .share:
        return "square.and.arrow.up"
      }
    }

    func count(viewModel: StatusRowViewModel, theme: Theme) -> Int? {
      if theme.statusActionsDisplay == .discret {
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

    func tintColor(viewModel: StatusRowViewModel, theme: Theme) -> Color? {
      switch self {
      case .respond, .share:
        return nil
      case .favorite:
        return viewModel.isFavorited ? .yellow : nil
      case .bookmark:
        return viewModel.isBookmarked ? .pink : nil
      case .boost:
        return viewModel.isReblogged ? theme.tintColor : nil
      }
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        ForEach(Actions.allCases, id: \.self) { action in
          if action == .share {
            if let urlString = viewModel.status.reblog?.url ?? viewModel.status.url,
               let url = URL(string: urlString)
            {
              ShareLink(item: url,
                        subject: Text(viewModel.status.reblog?.account.safeDisplayName ?? viewModel.status.account.safeDisplayName),
                        message: Text(viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText)) {
                Image(systemName: action.iconName(viewModel: viewModel))
              }
              .buttonStyle(.borderless)
            }
          } else {
            Button {
              handleAction(action: action)
            } label: {
              HStack(spacing: 2) {
                Image(systemName: action.iconName(viewModel: viewModel, privateBoost: privateBoost()))
                  .foregroundColor(action.tintColor(viewModel: viewModel, theme: theme))
                if let count = action.count(viewModel: viewModel, theme: theme), !viewModel.isRemote {
                  Text("\(count)")
                    .font(.scaledFootnote)
                }
              }
            }
            .buttonStyle(.borderless)
            .disabled(action == .boost &&
                      (viewModel.status.visibility == .direct || viewModel.status.visibility == .priv && viewModel.status.account.id != currentAccount.account?.id))
            Spacer()
          }
        }
      }
      if viewModel.isFocused {
        StatusRowDetailView(viewModel: viewModel)
      }
    }
  }

  private func handleAction(action: Actions) {
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
