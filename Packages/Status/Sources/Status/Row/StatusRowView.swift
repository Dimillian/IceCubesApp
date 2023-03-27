import DesignSystem
import EmojiText
import Env
import Foundation
import Models
import Network
import Shimmer
import SwiftUI

public struct StatusRowView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(\.accessibilityEnabled) private var accessibilityEnabled

  @EnvironmentObject private var theme: Theme

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
          Group {
            StatusRowReblogView(viewModel: viewModel)
            StatusRowReplyView(viewModel: viewModel)
          }
          .padding(.leading, AvatarView.Size.status.size.width + .statusColumnsSpacing)
        }
        HStack(alignment: .top, spacing: .statusColumnsSpacing) {
          if !isCompact,
             theme.avatarPosition == .leading
          {
            Button {
              viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
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
      // The actions associated with the swipes are exposed as custom accessibility actions and there is no way to remove them.
      if !isCompact, accessibilityEnabled == false {
        StatusRowSwipeView(viewModel: viewModel, mode: .trailing)
      }
    }
    .swipeActions(edge: .leading) {
      // The actions associated with the swipes are exposed as custom accessibility actions and there is no way to remove them.
      if !isCompact, accessibilityEnabled == false {
        StatusRowSwipeView(viewModel: viewModel, mode: .leading)
      }
    }
    .listRowBackground(viewModel.highlightRowColor)
    .listRowInsets(.init(top: 12,
                         leading: .layoutPadding,
                         bottom: 12,
                         trailing: .layoutPadding))
    .accessibilityElement(children: viewModel.isFocused ? .contain : .combine)
    .accessibilityLabel(viewModel.isFocused == false && accessibilityEnabled
                        ? CombinedAccessibilityLabel(viewModel: viewModel).finalLabel() : Text(""))
    .accessibilityAction {
      viewModel.navigateToDetail()
    }
    .accessibilityActions {
      if viewModel.showActions {
        accessibilityActions
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
      StatusDataControllerProvider.shared.dataController(for: viewModel.finalStatus,
                                                         client: viewModel.client)
    )
  }

  @ViewBuilder
  private var accessibilityActions: some View {
    // Add reply and quote, which are lost when the swipe actions are removed
    Button("status.action.reply") {
      HapticManager.shared.fireHaptic(of: .notification(.success))
      viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
    }

    Button("settings.swipeactions.status.action.quote") {
      HapticManager.shared.fireHaptic(of: .notification(.success))
      viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
    }

    Button(viewModel.displaySpoiler ? "status.show-more" : "status.show-less") {
      withAnimation {
        viewModel.displaySpoiler.toggle()
      }
    }

    Button("@\(viewModel.status.account.username)") {
      HapticManager.shared.fireHaptic(of: .notification(.success))
      viewModel.routerPath.navigate(to: .accountDetail(id: viewModel.status.account.id))
    }

    // Add a reference to the post creator
    if viewModel.status.account != viewModel.finalStatus.account {
      Button("@\(viewModel.finalStatus.account.username)") {
        HapticManager.shared.fireHaptic(of: .notification(.success))
        viewModel.routerPath.navigate(to: .accountDetail(id: viewModel.finalStatus.account.id))
      }
    }

    // Add in each detected link in the content
    ForEach(viewModel.finalStatus.content.links) { link in
      switch link.type {
        case .url:
          if UIApplication.shared.canOpenURL(link.url) {
            Button("accessibility.tabs.timeline.content-link-\(link.title)") {
              HapticManager.shared.fireHaptic(of: .notification(.success))
              _ = viewModel.routerPath.handle(url: link.url)
            }
          }
        case .hashtag:
          Button("accessibility.tabs.timeline.content-hashtag-\(link.title)") {
            HapticManager.shared.fireHaptic(of: .notification(.success))
            _ = viewModel.routerPath.handle(url: link.url)
          }
        case .mention:
          Button("\(link.title)") {
            HapticManager.shared.fireHaptic(of: .notification(.success))
            _ = viewModel.routerPath.handle(url: link.url)
          }
      }
    }
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

/// A utility that creates a suitable combined accessibility label for a `StatusRowView` that is not focused.
@MainActor
private struct CombinedAccessibilityLabel {
  let viewModel: StatusRowViewModel

  var hasSpoiler: Bool {
    viewModel.displaySpoiler && viewModel.finalStatus.spoilerText.asRawText.isEmpty == false
  }

  var isReply: Bool {
    if let accountId = viewModel.status.inReplyToAccountId, viewModel.status.mentions.contains(where: { $0.id == accountId }) {
      return true
    }
    return false
  }

  var isBoost: Bool {
    viewModel.status.reblog != nil
  }

  func finalLabel() -> Text {
    userNamePreamble() +
      Text(hasSpoiler
        ? viewModel.finalStatus.spoilerText.asRawText
        : viewModel.finalStatus.content.asRawText
      ) +
      Text(hasSpoiler
        ? "status.editor.spoiler"
        : ""
      ) +
      pollText() +
      imageAltText() + Text(", ") +
      Text(viewModel.finalStatus.createdAt.relativeFormatted) + Text(", ") +
      Text("status.summary.n-replies \(viewModel.finalStatus.repliesCount)") + Text(", ") +
      Text("status.summary.n-boosts \(viewModel.finalStatus.reblogsCount)") + Text(", ") +
      Text("status.summary.n-favorites \(viewModel.finalStatus.favouritesCount)")
  }

  func userNamePreamble() -> Text {
    switch (isReply, isBoost) {
    case (true, false):
      return Text("accessibility.status.a-replied-to-\(finalUserDisplayName())") + Text(" ")
    case (_, true):
      return Text("accessibility.status.a-boosted-b-\(userDisplayName())-\(finalUserDisplayName())") + Text(", ")
    default:
      return Text(userDisplayName()) + Text(", ")
    }
  }

  func userDisplayName() -> String {
    viewModel.status.account.displayNameWithoutEmojis.count < 4
      ? viewModel.status.account.safeDisplayName
      : viewModel.status.account.displayNameWithoutEmojis
  }

  func finalUserDisplayName() -> String {
    viewModel.finalStatus.account.displayNameWithoutEmojis.count < 4
      ? viewModel.finalStatus.account.safeDisplayName
      : viewModel.finalStatus.account.displayNameWithoutEmojis
  }

  func imageAltText() -> Text {
    let descriptions = viewModel.finalStatus.mediaAttachments
      .compactMap(\.description)

    if descriptions.count == 1 {
      return Text("accessibility.image.alt-text-\(descriptions[0])")
    } else if descriptions.count > 1 {
      return Text("accessibility.image.alt-text-\(descriptions[0])") + Text(", ") + Text("accessibility.image.alt-text-more.label")
    } else {
      return Text("")
    }
  }

  func pollText() -> Text {
    if let poll = viewModel.finalStatus.poll {
      let showPercentage = poll.expired || poll.voted ?? false
      let title: LocalizedStringKey = poll.expired
        ? "accessibility.status.poll.finished.label"
        : "accessibility.status.poll.active.label"

      return poll.options.enumerated().reduce(into: Text(title)) { text, pair in
        let (index, option) = pair
        let selected = poll.ownVotes?.contains(index) ?? false
        let percentage = poll.safeVotersCount > 0
          ? Int(round(Double(option.votesCount) / Double(poll.safeVotersCount) * 100))
          : 0

        text = text +
        Text(selected ? "accessibility.status.poll.selected.label" : "") +
        Text(", ") +
        Text("accessibility.status.poll.option-prefix-\(index + 1)-of-\(poll.options.count)") +
        Text(option.title) +
        Text(showPercentage ? "\(percentage)%" : "") +
        Text(". ")
      }
    }
    return Text("")
  }
}
