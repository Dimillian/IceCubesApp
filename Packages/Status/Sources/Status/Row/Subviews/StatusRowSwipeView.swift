import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowSwipeView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var preferences: UserPreferences

  enum Mode {
    case leading, trailing
  }

  let viewModel: StatusRowViewModel
  let mode: Mode

  var body: some View {
    switch mode {
    case .leading:
      leadingSwipeActions
    case .trailing:
      trailingSwipeActions
    }
  }

  @ViewBuilder
  private var trailingSwipeActions: some View {
    if preferences.swipeActionsStatusTrailingRight != StatusAction.none, !viewModel.isRemote {
      makeSwipeButton(action: preferences.swipeActionsStatusTrailingRight)
        .tint(preferences.swipeActionsStatusTrailingRight.color(themeTintColor: theme.tintColor, useThemeColor: preferences.swipeActionsUseThemeColor, outside: true))
    }
    if preferences.swipeActionsStatusTrailingLeft != StatusAction.none, !viewModel.isRemote {
      makeSwipeButton(action: preferences.swipeActionsStatusTrailingLeft)
        .tint(preferences.swipeActionsStatusTrailingLeft.color(themeTintColor: theme.tintColor, useThemeColor: preferences.swipeActionsUseThemeColor, outside: false))
    }
  }

  @ViewBuilder
  private var leadingSwipeActions: some View {
    if preferences.swipeActionsStatusLeadingLeft != StatusAction.none, !viewModel.isRemote {
      makeSwipeButton(action: preferences.swipeActionsStatusLeadingLeft)
        .tint(preferences.swipeActionsStatusLeadingLeft.color(themeTintColor: theme.tintColor, useThemeColor: preferences.swipeActionsUseThemeColor, outside: true))
    }
    if preferences.swipeActionsStatusLeadingRight != StatusAction.none, !viewModel.isRemote {
      makeSwipeButton(action: preferences.swipeActionsStatusLeadingRight)
        .tint(preferences.swipeActionsStatusLeadingRight.color(themeTintColor: theme.tintColor, useThemeColor: preferences.swipeActionsUseThemeColor, outside: false))
    }
  }

  @ViewBuilder
  private func makeSwipeButton(action: StatusAction) -> some View {
    switch action {
    case .reply:
      makeSwipeButtonForRouterPath(action: action, destination: .replyToStatusEditor(status: viewModel.status))
    case .quote:
      makeSwipeButtonForRouterPath(action: action, destination: .quoteStatusEditor(status: viewModel.status))
    case .favorite:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isFavorited {
          await viewModel.unFavorite()
        } else {
          await viewModel.favorite()
        }
      }
    case .boost:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isReblogged {
          await viewModel.unReblog()
        } else {
          await viewModel.reblog()
        }
      }
    case .bookmark:
      makeSwipeButtonForTask(action: action) {
        if viewModel.isBookmarked {
          await viewModel.unbookmark()
        } else {
          await
            viewModel.bookmark()
        }
      }
    case .none:
      EmptyView()
    }
  }

  @ViewBuilder
  private func makeSwipeButtonForRouterPath(action: StatusAction, destination: SheetDestination) -> some View {
    Button {
      HapticManager.shared.fireHaptic(of: .notification(.success))
      viewModel.routerPath.presentedSheet = destination
    } label: {
      makeSwipeLabel(action: action, style: preferences.swipeActionsIconStyle)
    }
  }

  @ViewBuilder
  private func makeSwipeButtonForTask(action: StatusAction, task: @escaping () async -> Void) -> some View {
    Button {
      Task {
        HapticManager.shared.fireHaptic(of: .notification(.success))
        await task()
      }
    } label: {
      makeSwipeLabel(action: action, style: preferences.swipeActionsIconStyle)
    }
  }

  @ViewBuilder
  private func makeSwipeLabel(action: StatusAction, style: UserPreferences.SwipeActionsIconStyle) -> some View {
    switch style {
    case .iconOnly:
      Label(action.displayName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked), systemImage: action.iconName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
        .labelStyle(.iconOnly)
        .environment(\.symbolVariants, .none)
    case .iconWithText:
      Label(action.displayName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked), systemImage: action.iconName(isReblogged: viewModel.isReblogged, isFavorited: viewModel.isFavorited, isBookmarked: viewModel.isBookmarked))
        .labelStyle(.titleAndIcon)
        .environment(\.symbolVariants, .none)
    }
  }
}
