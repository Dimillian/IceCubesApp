import DesignSystem
import EmojiText
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct StatusRowView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact: Bool
  
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  
  @StateObject var viewModel: StatusRowViewModel
  
  // StateObject accepts an @autoclosure which only allocates the view model once when the view gets on screen.
  public init(viewModel: @escaping () -> StatusRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel())
  }
  
  var contextMenu: some View {
    StatusRowContextMenu(viewModel: viewModel)
  }
  
  public var body: some View {
    VStack(alignment: .leading) {
      if viewModel.isFiltered, let filter = viewModel.filter {
        switch filter.filter.filterAction {
        case .warn:
          makeFilterView(filter: filter.filter)
        case .hide:
          EmptyView()
        }
      } else {
        if !isCompact, theme.avatarPosition == .leading {
          StatusRowReblogView(viewModel: viewModel)
          StatusRowReplyView(viewModel: viewModel)
        }
        HStack(alignment: .top, spacing: .statusColumnsSpacing) {
          if !isCompact,
             theme.avatarPosition == .leading
          {
            Button {
              viewModel.routerPath.navigate(to: .accountDetailWithAccount(account: viewModel.finalStatus.account))
            } label: {
              AvatarView(url: viewModel.finalStatus.account.avatar, size: .status)
            }
          }
          VStack(alignment: .leading) {
            if !isCompact, theme.avatarPosition == .top {
              StatusRowReblogView(viewModel: viewModel)
              StatusRowReplyView(viewModel: viewModel)
            }
            VStack(alignment: .leading, spacing: 8) {
              if !isCompact {
                StatusRowHeaderView(viewModel: viewModel)
              }
              StatusRowContentView(viewModel: viewModel)
                .contentShape(Rectangle())
                .onTapGesture {
                  viewModel.navigateToDetail()
                }
            }
            .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
            .accessibilityAction {
              viewModel.navigateToDetail()
            }
            if viewModel.showActions, viewModel.isFocused || theme.statusActionsDisplay != .none, !isInCaptureMode {
              StatusRowActionsView(viewModel: viewModel)
                .padding(.top, 8)
                .tint(viewModel.isFocused ? theme.tintColor : .gray)
                .contentShape(Rectangle())
                .onTapGesture {
                  viewModel.navigateToDetail()
                }
            }
          }
        }
      }
    }
    .onAppear {
      viewModel.markSeen()
      if reasons.isEmpty {
        if !isCompact, viewModel.embeddedStatus == nil {
          Task {
            await viewModel.loadEmbeddedStatus()
          }
        }
      }
    }
    .contextMenu {
      contextMenu
    }
    .swipeActions(edge: .trailing) {
      if !isCompact {
        StatusRowSwipeView(viewModel: viewModel, mode: .trailing)
      }
    }
    .swipeActions(edge: .leading) {
      if !isCompact {
        StatusRowSwipeView(viewModel: viewModel, mode: .leading)
      }
    }
    .listRowBackground(viewModel.highlightRowColor)
    .listRowInsets(.init(top: 12,
                         leading: .layoutPadding,
                         bottom: 12,
                         trailing: .layoutPadding))
    .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
    .accessibilityActions {
      if UIAccessibility.isVoiceOverRunning {
        accesibilityActions
      }
    }
    .background {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          viewModel.navigateToDetail()
        }
    }
    .overlay {
      if viewModel.isLoadingRemoteContent {
        remoteContentLoadingView
      }
    }
    .alert(isPresented: $viewModel.showDeleteAlert, content: {
      Alert(
        title: Text("status.action.delete.confirm.title"),
        message: Text("status.action.delete.confirm.message"),
        primaryButton: .destructive(
          Text("status.action.delete"))
        {
          Task {
            await viewModel.delete()
          }
        },
        secondaryButton: .cancel()
      )
    })
    .alignmentGuide(.listRowSeparatorLeading) { _ in
      -100
    }
    .environmentObject(
      StatusDataControllerProvider.shared.dataController(for: viewModel.status.reblog ?? viewModel.status,
                                                         client: client)
    )
  }
  
  @ViewBuilder
  private var accesibilityActions: some View {
    // Add the individual mentions as accessibility actions
    ForEach(viewModel.status.mentions, id: \.id) { mention in
      Button("@\(mention.username)") {
        viewModel.routerPath.navigate(to: .accountDetail(id: mention.id))
      }
    }
    
    Button(viewModel.displaySpoiler ? "status.show-more" : "status.show-less") {
      withAnimation {
        viewModel.displaySpoiler.toggle()
      }
    }
    
    Button("@\(viewModel.status.account.username)") {
      viewModel.routerPath.navigate(to: .accountDetail(id: viewModel.status.account.id))
    }
    
    contextMenu
  }
  
  private func makeFilterView(filter: Filter) -> some View {
    HStack {
      Text("status.filter.filtered-by-\(filter.title)")
      Button {
        withAnimation {
          viewModel.isFiltered = false
        }
      } label: {
        Text("status.filter.show-anyway")
      }
    }
  }
  
  private var remoteContentLoadingView: some View {
    ZStack(alignment: .center) {
      VStack {
        Spacer()
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        Spacer()
      }
    }
    .background(Color.black.opacity(0.40))
    .transition(.opacity)
  }
}
