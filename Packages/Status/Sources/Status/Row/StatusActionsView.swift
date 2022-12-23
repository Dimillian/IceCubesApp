import SwiftUI
import Models
import Env
import Network

struct StatusActionsView: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @ObservedObject var viewModel: StatusRowViewModel
    
  @MainActor
  enum Actions: CaseIterable {
    case respond, boost, favourite, share
    
    func iconName(viewModel: StatusRowViewModel) -> String {
      switch self {
      case .respond:
        return "bubble.right"
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
  }
  
  var body: some View {
    HStack {
      ForEach(Actions.allCases, id: \.self) { action in
        Button {
          handleAction(action: action)
        } label: {
          HStack(spacing: 2) {
            Image(systemName: action.iconName(viewModel: viewModel))
            if let count = action.count(viewModel: viewModel) {
              Text("\(count)")
                .font(.footnote)
            }
          }
        }
        if action != .share {
          Spacer()
        }
      }
    }
    .tint(.gray)
  }
  
  private func handleAction(action: Actions) {
    Task {
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
