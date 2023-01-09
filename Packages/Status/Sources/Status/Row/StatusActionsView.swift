import SwiftUI
import Models
import Env
import Network
import DesignSystem

struct StatusActionsView: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var routeurPath: RouterPath
  @ObservedObject var viewModel: StatusRowViewModel
  
  let generator = UINotificationFeedbackGenerator()
  
  @MainActor
  enum Actions: CaseIterable {
    case respond, boost, favourite, bookmark, share
    
    func iconName(viewModel: StatusRowViewModel) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
        return viewModel.isReblogged ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
      case .favourite:
        return viewModel.isFavourited ? "star.fill" : "star"
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
      case .favourite:
        return viewModel.favouritesCount
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
      case .favourite:
        return viewModel.isFavourited ? .yellow : nil
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
                    .font(.footnote)
                }
              }
            }
            .buttonStyle(.borderless)
            .disabled(action == .boost && viewModel.status.visibility == .direct)
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
    HStack {
      Text(viewModel.status.createdAt.asDate, style: .date)
      Text(viewModel.status.createdAt.asDate, style: .time)
      Text("·")
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
    .font(.caption)
    .foregroundColor(.gray)
    if viewModel.favouritesCount > 0 {
      Divider()
      Button {
        routeurPath.navigate(to: .favouritedBy(id: viewModel.status.id))
      } label: {
        HStack {
          Text("\(viewModel.favouritesCount) favorites")
          Spacer()
          Image(systemName: "chevron.right")
        }
        .font(.callout)
      }
    }
    if viewModel.reblogsCount > 0 {
      Divider()
      Button {
        routeurPath.navigate(to: .rebloggedBy(id: viewModel.status.id))
      } label: {
        HStack {
          Text("\(viewModel.reblogsCount) boosts")
          Spacer()
          Image(systemName: "chevron.right")
        }
        .font(.callout)
      }
    }
  }
  
  private func handleAction(action: Actions) {
    Task {
      generator.notificationOccurred(.success)
      switch action {
      case .respond:
        routeurPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
      case .favourite:
        if viewModel.isFavourited {
          await viewModel.unFavourite()
        } else {
          await viewModel.favourite()
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
