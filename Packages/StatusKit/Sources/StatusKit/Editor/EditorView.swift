import AppAccount
import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

extension StatusEditor {
  @MainActor
  struct EditorView: View {
    @Environment(Theme.self) private var theme
    @Environment(UserPreferences.self) private var preferences
    @Environment(CurrentAccount.self) private var currentAccount
    @Environment(CurrentInstance.self) private var currentInstance
    @Environment(AppAccountsManager.self) private var appAccounts
    @Environment(MastodonClient.self) private var client

    #if targetEnvironment(macCatalyst)
      @Environment(\.dismissWindow) private var dismissWindow
    #else
      @Environment(\.dismiss) private var dismiss
    #endif

    @Namespace private var transition
    
    @Bindable var viewModel: ViewModel
    @Binding var followUpSEVMs: [ViewModel]
    @Binding var editingMediaContainer: MediaContainer?
    @Binding var presentationDetent: PresentationDetent

    @FocusState<UUID?> var isSpoilerTextFocused: UUID?
    @FocusState<EditorFocusState?>.Binding var editorFocusState: EditorFocusState?
    let assignedFocusState: EditorFocusState
    let isMain: Bool

    var body: some View {
      HStack(spacing: 0) {
        if !isMain {
          Rectangle()
            .fill(theme.tintColor)
            .frame(width: 2)
            .accessibilityHidden(true)
            .padding(.leading, .layoutPadding)
        }

        VStack(spacing: 0) {
          spoilerTextView
          VStack(spacing: 0) {
            accountHeaderView
            textInput
            pollView
            characterCountAndLangView
            MediaView(viewModel: viewModel, editingMediaContainer: $editingMediaContainer)
            embeddedStatus
          }
          .padding(.vertical)

          Divider()
        }
      }
      #if !os(visionOS)
        .background(presentationDetent == .large ? theme.primaryBackgroundColor : .clear)
      #endif
      .focused($editorFocusState, equals: assignedFocusState)
      .onAppear { setupViewModel() }
    }

    @ViewBuilder
    private var spoilerTextView: some View {
      if viewModel.spoilerOn {
        TextField("status.editor.spoiler", text: $viewModel.spoilerText)
          .focused($isSpoilerTextFocused, equals: viewModel.id)
          .padding(.horizontal, .layoutPadding)
          .padding(.vertical)
          .background(theme.tintColor.opacity(0.20))
      }
    }

    @ViewBuilder
    private var accountHeaderView: some View {
      if let account = currentAccount.account, !viewModel.mode.isEditing {
        HStack {
          if viewModel.mode.isInShareExtension {
            AppAccountsSelectorView(
              transition: transition,
              routerPath: RouterPath(),
              accountCreationEnabled: false,
              avatarConfig: .status)
          } else {
            AvatarView(account.avatar, config: AvatarView.FrameConfig.status)
              .environment(theme)
              .accessibilityHidden(true)
          }

          VStack(alignment: .leading, spacing: 4) {
            PrivacyMenu(
              visibility: $viewModel.visibility, tint: isMain ? theme.tintColor : .secondary
            )
            .disabled(!isMain)

            Text("@\(account.acct)@\(appAccounts.currentClient.server)")
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
          }

          Spacer()

          if case .followUp(let id) = assignedFocusState {
            Button {
              followUpSEVMs.removeAll { $0.id == id }
            } label: {
              HStack {
                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
              }
            }
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
    }

    private var textInput: some View {
      TextView(
        viewModel.statusTextBinding,
        getTextView: { textView in viewModel.textView = textView }
      )
      .placeholder(
        String(
          localized: isMain
            ? "status.editor.text.placeholder" : "status.editor.follow-up.text.placeholder")
      )
      .setKeyboardType(preferences.isSocialKeyboardEnabled ? .twitter : .default)
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical)
    }

    @ViewBuilder
    private var embeddedStatus: some View {
      if let status = viewModel.replyToStatus {
        Divider().padding(.vertical, .statusComponentSpacing)
        StatusRowView(
          viewModel: .init(
            status: status,
            client: client,
            routerPath: RouterPath(),
            showActions: false),
          context: .timeline
        )
        .accessibilityLabel(status.content.asRawText)
        .environment(RouterPath())
        .allowsHitTesting(false)
        .environment(\.isStatusFocused, false)
        .environment(\.isModal, true)
        .padding(.horizontal, .layoutPadding)
        .padding(.vertical, .statusComponentSpacing)
        #if os(visionOS)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background)
          )
          .buttonStyle(.plain)
          .padding(.layoutPadding)
        #endif

      } else if let status = viewModel.embeddedStatus {
        StatusEmbeddedView(status: status, client: client, routerPath: RouterPath())
          .padding(.horizontal, .layoutPadding)
          .disabled(true)
      }
    }

    @ViewBuilder
    private var pollView: some View {
      if viewModel.showPoll {
        PollView(viewModel: viewModel, showPoll: $viewModel.showPoll)
          .padding(.horizontal)
      }
    }

    @ViewBuilder
    private var characterCountAndLangView: some View {
      HStack(alignment: .center) {
        if #available(iOS 26.0, *) {
          LangButton(viewModel: viewModel)
            .glassEffect(.regular.interactive())
          pollButton
            .glassEffect(.regular.interactive())
          spoilerButton
            .glassEffect(.regular.interactive())
          Spacer()
          characterCount
            .padding(8)
            .glassEffect(.regular.interactive())
        } else {
          LangButton(viewModel: viewModel)
          pollButton
          spoilerButton
          Spacer()
          characterCount
        }

      }
      .padding(.vertical, 8)
      .padding(.leading, .layoutPadding)
      .padding(.trailing, .layoutPadding)
    }

    private var pollButton: some View {
      Button {
        withAnimation {
          viewModel.showPoll.toggle()
          viewModel.resetPollDefaults()
        }
      } label: {
        Image(systemName: viewModel.showPoll ? "chart.bar.fill" : "chart.bar")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("accessibility.editor.button.poll")
      .disabled(viewModel.shouldDisablePollButton)
    }

    private var spoilerButton: some View {
      Button {
        withAnimation {
          viewModel.spoilerOn.toggle()
        }
        isSpoilerTextFocused = viewModel.id
      } label: {
        Image(
          systemName: viewModel.spoilerOn
            ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("accessibility.editor.button.spoiler")
    }

    @ViewBuilder
    private var characterCount: some View {
      let value =
        (currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500)
        + viewModel.statusTextCharacterLength
      Text("\(value)")
        .contentTransition(.numericText(value: Double(value)))
        .foregroundColor(value < 0 ? .red : .secondary)
        .font(.callout.monospacedDigit())
        .accessibilityLabel("accessibility.editor.button.characters-remaining")
        .accessibilityValue("\(value)")
        .accessibilityRemoveTraits(.isStaticText)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityRespondsToUserInteraction(false)
        .animation(.smooth, value: value)
    }

    private func setupViewModel() {
      viewModel.client = client
      viewModel.currentAccount = currentAccount.account
      viewModel.theme = theme
      viewModel.preferences = preferences
      viewModel.currentInstance = currentInstance
      viewModel.prepareStatusText()
      if !client.isAuth {
        #if targetEnvironment(macCatalyst)
          dismissWindow()
        #else
          dismiss()
        #endif
        NotificationCenter.default.post(name: .shareSheetClose, object: nil)
      }

      Task { await viewModel.fetchCustomEmojis() }
    }
  }
}
