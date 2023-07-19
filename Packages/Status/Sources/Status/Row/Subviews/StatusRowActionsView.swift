import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct StatusRowActionsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var statusDataController: StatusDataController
  @EnvironmentObject private var userPreferences: UserPreferences
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
    public nonisolated static var allCases: [StatusRowActionsView.Action] {
      [.respond, .boost, .favorite, .bookmark, .share]
    }

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
            if let urlString = viewModel.finalStatus.url,
               let url = URL(string: urlString)
            {
              switch userPreferences.shareButtonBehavior {
              case .linkOnly:
                ShareLink(item: url) {
                  action.image(dataController: statusDataController)
                }
                .buttonStyle(.statusAction())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("status.action.share-link")
              case .linkAndText:
                ShareLink(item: url,
                          subject: Text(viewModel.finalStatus.account.safeDisplayName),
                          message: Text(viewModel.finalStatus.content.asRawText))
                {
                  action.image(dataController: statusDataController)
                }
                .buttonStyle(.statusAction())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("status.action.share-link")
              }
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
        if action == .boost {
          action
            .image(dataController: statusDataController, privateBoost: privateBoost())
            .imageScale(.medium)
            .font(.body)
            .fontWeight(.black)
        } else {
          action
            .image(dataController: statusDataController, privateBoost: privateBoost())
        }
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
                                  theme: theme), !viewModel.isRemote
      {
        Text("\(count)")
          .foregroundColor(Color(UIColor.secondaryLabel))
          .font(.scaledFootnote)
          .monospacedDigit()
      }
    }
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
      HapticManager.shared.fireHaptic(of: .notification(.success))
      switch action {
      case .respond:
        SoundEffectManager.shared.playSound(of: .share)
        viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.localStatus ?? viewModel.status)
      case .favorite:
        SoundEffectManager.shared.playSound(of: .favorite)
        await statusDataController.toggleFavorite(remoteStatus: viewModel.localStatusId)
      case .bookmark:
        SoundEffectManager.shared.playSound(of: .bookmark)
        await statusDataController.toggleBookmark(remoteStatus: viewModel.localStatusId)
      case .boost:
        SoundEffectManager.shared.playSound(of: .boost)
        await statusDataController.toggleReblog(remoteStatus: viewModel.localStatusId)
      default:
        break
      }
    }
  }
}
