import DesignSystem
import EmojiText
import Env
import Foundation
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct StatusRowView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(\.accessibilityVoiceOverEnabled) private var accessibilityVoiceOverEnabled
  @Environment(\.isStatusFocused) private var isFocused
  @Environment(\.indentationLevel) private var indentationLevel
  @Environment(\.isHomeTimeline) private var isHomeTimeline

  @Environment(RouterPath.self) private var routerPath: RouterPath
  @Environment(QuickLook.self) private var quickLook
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  @State private var showSelectableText: Bool = false
  @State private var isShareAsImageSheetPresented: Bool = false
  @State private var isBlockConfirmationPresented = false

  public enum Context { case timeline, detail }

  @State public var viewModel: StatusRowViewModel
  public let context: Context

  var contextMenu: some View {
    StatusRowContextMenu(
      viewModel: viewModel,
      showTextForSelection: $showSelectableText,
      isBlockConfirmationPresented: $isBlockConfirmationPresented,
      isShareAsImageSheetPresented: $isShareAsImageSheetPresented)
  }

  public var body: some View {
    HStack(spacing: 0) {
      if !isCompact {
        HStack(spacing: 3) {
          ForEach(0..<indentationLevel, id: \.self) { level in
            Rectangle()
              .fill(theme.tintColor)
              .frame(width: 2)
              .accessibilityHidden(true)
              .opacity((indentationLevel == level + 1) ? 1 : 0.15)
          }
        }
        if indentationLevel > 0 {
          Spacer(minLength: 8)
        }
      }
      VStack(alignment: .leading, spacing: .statusComponentSpacing) {
        if viewModel.isFiltered, let filter = viewModel.filter {
          switch filter.filter.filterAction {
          case .warn:
            makeFilterView(filter: filter.filter)
          case .hide:
            EmptyView()
          }
        } else {
          if !isCompact && context != .detail {
            Group {
              StatusRowTagView(viewModel: viewModel)
              StatusRowReblogView(viewModel: viewModel)
              StatusRowReplyView(viewModel: viewModel)
            }
            .padding(
              .leading,
              theme.avatarPosition == .top
                ? 0 : AvatarView.FrameConfig.status.width + .statusColumnsSpacing)
          }
          HStack(alignment: .top, spacing: .statusColumnsSpacing) {
            if !isCompact,
              theme.avatarPosition == .leading
            {
              AvatarView(viewModel.finalStatus.account.avatar)
                .accessibility(addTraits: .isButton)
                .contentShape(Circle())
                .hoverEffect()
                .onTapGesture {
                  viewModel.navigateToAccountDetail(account: viewModel.finalStatus.account)
                }
            }
            VStack(alignment: .leading, spacing: .statusComponentSpacing) {
              if !isCompact {
                StatusRowHeaderView(viewModel: viewModel)
              }
              StatusRowContentView(viewModel: viewModel)
                .contentShape(Rectangle())
                .onTapGesture {
                  guard !isFocused else { return }
                  viewModel.navigateToDetail()
                }
                .accessibilityActions {
                  if isFocused, viewModel.showActions {
                    accessibilityActions
                  }
                }
              if !reasons.contains(.placeholder),
                viewModel.showActions, isFocused || theme.statusActionsDisplay != .none,
                !isInCaptureMode
              {
                StatusRowActionsView(
                  isBlockConfirmationPresented: $isBlockConfirmationPresented,
                  viewModel: viewModel
                )
                .tint(isFocused ? theme.tintColor : .gray)
              }

              if isFocused, !isCompact {
                StatusRowDetailView(viewModel: viewModel)
              }
            }
          }
        }
      }
      .padding(.init(top: isCompact ? 6 : 12, leading: 0, bottom: isFocused ? 12 : 6, trailing: 0))
    }
    .onAppear {
      if !reasons.contains(.placeholder) {
        if !isCompact, viewModel.embeddedStatus == nil {
          Task {
            await viewModel.loadEmbeddedStatus()
          }
        }
      }
    }
    .if(viewModel.url != nil) { $0.draggable(viewModel.url!) }
    .contextMenu {
      contextMenu
        .tint(.primary)
        .onAppear {
          Task {
            await viewModel.loadAuthorRelationship()
          }
        }
    }
    .swipeActions(edge: .trailing) {
      // The actions associated with the swipes are exposed as custom accessibility actions and there is no way to remove them.
      if !isCompact, accessibilityVoiceOverEnabled == false {
        StatusRowSwipeView(viewModel: viewModel, mode: .trailing)
      }
    }
    .swipeActions(edge: .leading) {
      // The actions associated with the swipes are exposed as custom accessibility actions and there is no way to remove them.
      if !isCompact, accessibilityVoiceOverEnabled == false {
        StatusRowSwipeView(viewModel: viewModel, mode: .leading)
      }
    }
    #if os(visionOS)
      .listRowBackground(
        RoundedRectangle(cornerRadius: 8)
          .foregroundStyle(.background).hoverEffect()
      )
      .listRowHoverEffectDisabled()
    #else
      .listRowBackground(viewModel.backgroundColor)
    #endif
    .listRowInsets(
      .init(
        top: 0,
        leading: .layoutPadding,
        bottom: 0,
        trailing: .layoutPadding)
    )
    .accessibilityElement(children: isFocused ? .contain : .combine)
    .accessibilityLabel(
      isFocused == false && accessibilityVoiceOverEnabled
        ? StatusRowAccessibilityLabel(viewModel: viewModel).finalLabel() : Text("")
    )
    .accessibilityHidden(viewModel.filter?.filter.filterAction == .hide)
    .accessibilityAction {
      guard !isFocused else { return }
      viewModel.navigateToDetail()
    }
    .accessibilityActions {
      if !isFocused, viewModel.showActions, accessibilityVoiceOverEnabled {
        accessibilityActions
      }
    }
    .background {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          guard !isFocused else { return }
          viewModel.navigateToDetail()
        }
    }
    .overlay {
      if viewModel.isLoadingRemoteContent {
        remoteContentLoadingView
      }
    }
    .alert(
      isPresented: $viewModel.showDeleteAlert,
      content: {
        Alert(
          title: Text("status.action.delete.confirm.title"),
          message: Text("status.action.delete.confirm.message"),
          primaryButton: .destructive(
            Text("status.action.delete")
          ) {
            Task {
              await viewModel.delete()
            }
          },
          secondaryButton: .cancel()
        )
      }
    )
    .confirmationDialog(
      "",
      isPresented: $isBlockConfirmationPresented
    ) {
      Button("account.action.block", role: .destructive) {
        Task {
          do {
            let operationAccount = viewModel.status.reblog?.account ?? viewModel.status.account
            viewModel.authorRelationship = try await client.post(
              endpoint: Accounts.block(id: operationAccount.id))
          } catch {}
        }
      }
    }
    .alignmentGuide(.listRowSeparatorLeading) { _ in
      -100
    }
    .sheet(isPresented: $showSelectableText) {
      let content =
        viewModel.status.reblog?.content.asSafeMarkdownAttributedString
        ?? viewModel.status.content.asSafeMarkdownAttributedString
      StatusRowSelectableTextView(content: content)
    }
    .environment(
      StatusDataControllerProvider.shared.dataController(
        for: viewModel.finalStatus,
        client: viewModel.client)
    )
    .alert(
      "DeepL couldn't be reached!\nIs the API Key correct?",
      isPresented: $viewModel.deeplTranslationError
    ) {
      Button("alert.button.ok", role: .cancel) {}
      Button("settings.general.translate") {
        RouterPath.settingsStartingPoint = .translation
        routerPath.presentedSheet = .settings
      }
    }
    .alert(
      "The Translation Service of your Instance couldn't be reached!",
      isPresented: $viewModel.instanceTranslationError
    ) {
      Button("alert.button.ok", role: .cancel) {}
      Button("settings.general.translate") {
        RouterPath.settingsStartingPoint = .translation
        routerPath.presentedSheet = .settings
      }
    }
    #if canImport(_Translation_SwiftUI)
      .addTranslateView(
        isPresented: $viewModel.showAppleTranslation, text: viewModel.finalStatus.content.asRawText)
    #endif
  }

  @ViewBuilder
  private var accessibilityActions: some View {
    // Add reply and quote, which are lost when the swipe actions are removed
    Button("status.action.reply") {
      HapticManager.shared.fireHaptic(.notification(.success))
      viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
    }

    Button("settings.swipeactions.status.action.quote") {
      HapticManager.shared.fireHaptic(.notification(.success))
      viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
    }
    .disabled(viewModel.status.visibility == .direct || viewModel.status.visibility == .priv)

    if viewModel.finalStatus.mediaAttachments.isEmpty == false {
      Button("accessibility.status.media-viewer-action.label") {
        HapticManager.shared.fireHaptic(.notification(.success))
        let attachments = viewModel.finalStatus.mediaAttachments
        #if targetEnvironment(macCatalyst) || os(visionOS)
          openWindow(
            value: WindowDestinationMedia.mediaViewer(
              attachments: attachments,
              selectedAttachment: attachments[0]
            ))
        #else
          quickLook.prepareFor(
            selectedMediaAttachment: attachments[0], mediaAttachments: attachments)
        #endif
      }
    }

    Button(viewModel.displaySpoiler ? "status.show-more" : "status.show-less") {
      withAnimation {
        viewModel.displaySpoiler.toggle()
      }
    }

    Button("@\(viewModel.status.account.username)") {
      HapticManager.shared.fireHaptic(.notification(.success))
      viewModel.routerPath.navigate(to: .accountDetail(id: viewModel.status.account.id))
    }

    // Add a reference to the post creator
    if viewModel.status.account != viewModel.finalStatus.account {
      Button("@\(viewModel.finalStatus.account.username)") {
        HapticManager.shared.fireHaptic(.notification(.success))
        viewModel.routerPath.navigate(to: .accountDetail(id: viewModel.finalStatus.account.id))
      }
    }

    // Add in each detected link in the content
    ForEach(viewModel.finalStatus.content.links) { link in
      switch link.type {
      case .url:
        if UIApplication.shared.canOpenURL(link.url) {
          Button("accessibility.tabs.timeline.content-link-\(link.title)") {
            HapticManager.shared.fireHaptic(.notification(.success))
            _ = viewModel.routerPath.handle(url: link.url)
          }
        }
      case .hashtag:
        Button("accessibility.tabs.timeline.content-hashtag-\(link.title)") {
          HapticManager.shared.fireHaptic(.notification(.success))
          _ = viewModel.routerPath.handle(url: link.url)
        }
      case .mention:
        Button("\(link.title)") {
          HapticManager.shared.fireHaptic(.notification(.success))
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
          .foregroundStyle(theme.tintColor)
      }
      .buttonStyle(.plain)
    }
    .onTapGesture {
      withAnimation {
        viewModel.isFiltered = false
      }
    }
    .accessibilityAction {
      viewModel.isFiltered = false
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

#Preview {
  List {
    StatusRowView(
      viewModel:
        .init(
          status: .placeholder(),
          client: .init(server: ""),
          routerPath: RouterPath()),
      context: .timeline)
    StatusRowView(
      viewModel:
        .init(
          status: .placeholder(),
          client: .init(server: ""),
          routerPath: RouterPath()),
      context: .timeline)
    StatusRowView(
      viewModel:
        .init(
          status: .placeholder(),
          client: .init(server: ""),
          routerPath: RouterPath()),
      context: .timeline)
  }
  .listStyle(.plain)
  .withPreviewsEnv()
  .environment(Theme.shared)
}
