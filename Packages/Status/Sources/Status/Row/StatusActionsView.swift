import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct StatusActionsView: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var routerPath: RouterPath
  @ObservedObject var viewModel: StatusRowViewModel

  let generator = UINotificationFeedbackGenerator()

  @MainActor
  enum Actions: CaseIterable {
    case respond, boost, favorite, bookmark, share

    func iconName(viewModel: StatusRowViewModel) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
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
            if let url = viewModel.status.reblog?.url ?? viewModel.status.url {
              ShareLink(item: url) {
                Image(systemName: action.iconName(viewModel: viewModel))
              }
            }
          } else {
            Button {
              handleAction(action: action)
            } label: {
              HStack(spacing: 2) {
                Image(systemName: action.iconName(viewModel: viewModel))
                  .foregroundColor(action.tintColor(viewModel: viewModel, theme: theme))
                if let count = action.count(viewModel: viewModel, theme: theme) {
                  Text("\(count)")
                    .font(.scaledFootnote)
                }
              }
            }
            .buttonStyle(.borderless)
            .disabled(action == .boost &&
                      (viewModel.status.visibility == .direct || viewModel.status.visibility == .priv))
            Spacer()
          }
        }
      }
      if viewModel.isFocused {
        summaryView
      }
    }
  }

  @ViewBuilder
  private var summaryView: some View {
    Divider()
    HStack {
      Text(viewModel.status.createdAt.asDate, style: .date) +
        Text("status.summary.at-time") +
        Text(viewModel.status.createdAt.asDate, style: .time) +
        Text("  ·")
      Image(systemName: viewModel.status.visibility.iconName)
      Spacer()
      Text(viewModel.status.application?.name ?? "")
        .underline()
        .onTapGesture {
          if let url = viewModel.status.application?.website {
            openURL(url)
          }
        }
    }
    .font(.scaledCaption)
    .foregroundColor(.gray)

    if let editedAt = viewModel.status.editedAt {
      Divider()
      HStack {
        Text("status.summary.edited-time") +
          Text(editedAt.asDate, style: .date) +
          Text("status.summary.at-time") +
          Text(editedAt.asDate, style: .time)
        Spacer()
      }
      .onTapGesture {
        routerPath.presentedSheet = .statusEditHistory(status: viewModel.status.id)
      }
      .underline()
      .font(.scaledCaption)
      .foregroundColor(.gray)
    }

    if viewModel.favoritesCount > 0 {
      Divider()
      NavigationLink(value: RouterDestinations.favoritedBy(id: viewModel.status.id)) {
        Text("status.summary.n-favorites \(viewModel.favoritesCount)")
          .font(.scaledCallout)
        Spacer()
        Image(systemName: "chevron.right")
      }
    }
    if viewModel.reblogsCount > 0 {
      Divider()
      NavigationLink(value: RouterDestinations.rebloggedBy(id: viewModel.status.id)) {
        Text("status.summary.n-boosts \(viewModel.reblogsCount)")
          .font(.scaledCallout)
        Spacer()
        Image(systemName: "chevron.right")
      }
    }
  }

  private func handleAction(action: Actions) {
    Task {
      generator.notificationOccurred(.success)
      switch action {
      case .respond:
        routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
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
