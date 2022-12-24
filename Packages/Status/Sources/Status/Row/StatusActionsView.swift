import SwiftUI
import Models
import Env
import Network
import DesignSystem

struct StatusActionsView: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @ObservedObject var viewModel: StatusRowViewModel
  
  let generator = UINotificationFeedbackGenerator()
  
  @MainActor
  enum Actions: CaseIterable {
    case respond, boost, favourite, share
    
    func iconName(viewModel: StatusRowViewModel) -> String {
      switch self {
      case .respond:
        return "arrowshape.turn.up.left"
      case .boost:
        return viewModel.isReblogged ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right.circle"
      case .favourite:
        return viewModel.isFavourited ? "star.fill" : "star"
      case .share:
        return "square.and.arrow.up"
      }
    }
    
    func count(viewModel: StatusRowViewModel) -> Int? {
      switch self {
      case .respond:
        return viewModel.repliesCount
      case .favourite:
        return viewModel.favouritesCount
      case .boost:
        return viewModel.reblogsCount
      case .share:
        return nil
      }
    }
    
    func tintColor(viewModel: StatusRowViewModel) -> Color? {
      switch self {
      case .respond, .share:
        return nil
      case .favourite:
        return viewModel.isFavourited ? .yellow : nil
      case .boost:
        return viewModel.isReblogged ? .brand : nil
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
                  .foregroundColor(action.tintColor(viewModel: viewModel))
                if let count = action.count(viewModel: viewModel) {
                  Text("\(count)")
                    .font(.footnote)
                }
              }
            }
            .buttonStyle(.borderless)
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
      Spacer()
      Text(viewModel.status.application?.name ?? "")
    }
    .font(.caption)
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
        routeurPath.navigate(to: .statusDetail(id: viewModel.status.reblog?.id ?? viewModel.status.id))
      case .favourite:
        if viewModel.isFavourited {
          await viewModel.unFavourite()
        } else {
          await viewModel.favourite()
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
