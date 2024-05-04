import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import Network
import NukeUI
import PhotosUI
import StoreKit
import SwiftUI
import UIKit

public extension StatusEditor {
  @MainActor
  struct MainView: View {
    @Environment(AppAccountsManager.self) private var appAccounts
    @Environment(CurrentAccount.self) private var currentAccount
    @Environment(Theme.self) private var theme

    @State private var presentationDetent: PresentationDetent = .large
    @State private var mainSEVM: ViewModel
    @State private var followUpSEVMs: [ViewModel] = []
    @State private var editingMediaContainer: MediaContainer?
    @State private var scrollID: UUID?

    @FocusState private var editorFocusState: EditorFocusState?

    private var focusedSEVM: ViewModel {
      if case let .followUp(id) = editorFocusState,
         let sevm = followUpSEVMs.first(where: { $0.id == id })
      { return sevm }

      return mainSEVM
    }

    public init(mode: ViewModel.Mode) {
      _mainSEVM = State(initialValue: ViewModel(mode: mode))
    }

    public var body: some View {
      @Bindable var focusedSEVM = focusedSEVM

      NavigationStack {
        ZStack(alignment: .top) {
          ScrollView {
            VStackLayout(spacing: 0) {
              EditorView(
                viewModel: mainSEVM,
                followUpSEVMs: $followUpSEVMs,
                editingMediaContainer: $editingMediaContainer,
                editorFocusState: $editorFocusState,
                assignedFocusState: .main,
                isMain: true
              )
              .id(mainSEVM.id)

              ForEach(followUpSEVMs) { sevm in
                @Bindable var sevm: ViewModel = sevm

                EditorView(
                  viewModel: sevm,
                  followUpSEVMs: $followUpSEVMs,
                  editingMediaContainer: $editingMediaContainer,
                  editorFocusState: $editorFocusState,
                  assignedFocusState: .followUp(index: sevm.id),
                  isMain: false
                )
                .id(sevm.id)
              }
            }
            .scrollTargetLayout()
          }
          .scrollPosition(id: $scrollID, anchor: .top)
          .animation(.bouncy(duration: 0.3), value: editorFocusState)
          .animation(.bouncy(duration: 0.3), value: followUpSEVMs)
          #if !os(visionOS)
            .background(theme.primaryBackgroundColor)
          #endif
            .safeAreaInset(edge: .bottom) {
              AutoCompleteView(viewModel: focusedSEVM)
            }
          #if os(visionOS)
            .ornament(attachmentAnchor: .scene(.leading)) {
              AccessoryView(focusedSEVM: focusedSEVM,
                            followUpSEVMs: $followUpSEVMs)
            }
          #else
            .safeAreaInset(edge: .bottom) {
                if presentationDetent == .large || presentationDetent == .medium {
                  AccessoryView(focusedSEVM: focusedSEVM,
                                followUpSEVMs: $followUpSEVMs)
                }
              }
          #endif
              .accessibilitySortPriority(1) // Ensure that all elements inside the `ScrollView` occur earlier than the accessory views
              .navigationTitle(focusedSEVM.mode.title)
              .navigationBarTitleDisplayMode(.inline)
              .toolbar { ToolbarItems(mainSEVM: mainSEVM,
                                      focusedSEVM: focusedSEVM,
                                      followUpSEVMs: followUpSEVMs) }
              .toolbarBackground(.visible, for: .navigationBar)
              .alert(
                "status.error.posting.title",
                isPresented: $focusedSEVM.showPostingErrorAlert,
                actions: {
                  Button("OK") {}
                }, message: {
                  Text(mainSEVM.postingError ?? "")
                }
              )
              .interactiveDismissDisabled(mainSEVM.shouldDisplayDismissWarning)
              .onChange(of: appAccounts.currentClient) { _, newValue in
                if mainSEVM.mode.isInShareExtension {
                  currentAccount.setClient(client: newValue)
                  mainSEVM.client = newValue
                  for post in followUpSEVMs {
                    post.client = newValue
                  }
                }
              }
              .onDrop(of: [.image, .video, .gif, .mpeg4Movie, .quickTimeMovie, .movie],
                      delegate: focusedSEVM)
              .onChange(of: currentAccount.account?.id) {
                mainSEVM.currentAccount = currentAccount.account
                for p in followUpSEVMs {
                  p.currentAccount = mainSEVM.currentAccount
                }
              }
              .onChange(of: mainSEVM.visibility) {
                for p in followUpSEVMs {
                  p.visibility = mainSEVM.visibility
                }
              }
              .onChange(of: followUpSEVMs.count) { oldValue, newValue in
                if oldValue < newValue {
                  Task {
                    try? await Task.sleep(for: .seconds(0.1))
                    withAnimation(.bouncy(duration: 0.5)) {
                      scrollID = followUpSEVMs.last?.id
                    }
                  }
                }
              }
          if mainSEVM.isPosting {
            ProgressView(value: mainSEVM.postingProgress, total: 100.0)
          }
        }
      }
      .sheet(item: $editingMediaContainer) { container in
        StatusEditor.MediaEditView(viewModel: focusedSEVM, container: container)
      }
      .presentationDetents([.large, .height(100)], selection: $presentationDetent)
      .presentationBackgroundInteraction(.enabled)
    }
  }
}
