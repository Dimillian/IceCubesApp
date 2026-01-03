import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import NukeUI
import PhotosUI
import StoreKit
import SwiftUI
import UIKit

extension StatusEditor {
  @MainActor
  public struct MainView: View {
    @Environment(AppAccountsManager.self) private var appAccounts
    @Environment(CurrentAccount.self) private var currentAccount
    @Environment(Theme.self) private var theme

    @State private var presentationDetent: PresentationDetent = .large
    @State private var mainStore: EditorStore
    @State private var followUpStores: [EditorStore] = []
    @State private var editingMediaContainer: MediaContainer?
    @State private var scrollID: UUID?
    @State private var isMediaPanelPresented: Bool = false
    @State private var lastEditorFocusState: EditorFocusState?

    @FocusState private var editorFocusState: EditorFocusState?

    private var focusedStore: EditorStore {
      if case .followUp(let id) = editorFocusState,
        let store = followUpStores.first(where: { $0.id == id })
      {
        return store
      }

      return mainStore
    }

    public init(mode: EditorStore.Mode) {
      _mainStore = State(initialValue: EditorStore(mode: mode))
    }

    public var body: some View {
      @Bindable var focusedStore = focusedStore

      NavigationStack {
        mainContent(focusedStore: focusedStore)
      }
      .sheet(item: $editingMediaContainer) { container in
        StatusEditor.MediaEditView(store: focusedStore, container: container)
      }
      .presentationDetents([.large, .height(230)], selection: $presentationDetent)
      .presentationBackgroundInteraction(.enabled)
    }

    @ViewBuilder
    private var backgroundColor: some View {
      if presentationDetent == .large {
        theme.primaryBackgroundColor.edgesIgnoringSafeArea(.all)
      }
      Color.clear
    }

    @ViewBuilder
    private func mainContent(focusedStore: EditorStore) -> some View {
      editorScrollView(focusedStore: focusedStore)
    }

    @ViewBuilder
    private func editorScrollView(focusedStore: EditorStore) -> some View {
      @Bindable var focusedStore = focusedStore

      ScrollView {
        editorStack
      }
      .scrollPosition(id: $scrollID, anchor: .top)
      .animation(.bouncy(duration: 0.3), value: editorFocusState)
      .animation(.bouncy(duration: 0.3), value: followUpStores)
      #if !os(visionOS)
        .background(backgroundColor)
      #endif
      #if os(visionOS)
        .ornament(attachmentAnchor: .scene(.leading)) {
          AccessoryView(
            focusedStore: focusedStore,
            followUpStores: $followUpStores,
            isMediaPanelPresented: $isMediaPanelPresented)
        }
      #else
        .safeAreaInset(edge: .bottom) {
          bottomInset(focusedStore: focusedStore)
        }
      #endif
      .accessibilitySortPriority(1)  // Ensure that all elements inside the `ScrollView` occur earlier than the accessory views
      .navigationTitle(focusedStore.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItems(
          mainStore: mainStore,
          focusedStore: focusedStore,
          followUpStores: followUpStores)
      }
      .alert(
        "status.error.posting.title",
        isPresented: $focusedStore.showPostingErrorAlert,
        actions: {
          Button("OK") {}
        },
        message: {
          Text(mainStore.postingError ?? "")
        }
      )
      .interactiveDismissDisabled(mainStore.shouldDisplayDismissWarning)
      .onChange(of: appAccounts.currentClient) { _, newValue in
        if mainStore.mode.isInShareExtension {
          currentAccount.setClient(client: newValue)
          mainStore.client = newValue
          for post in followUpStores {
            post.client = newValue
          }
        }
      }
      .onDrop(
        of: [.image, .video, .gif, .mpeg4Movie, .quickTimeMovie, .movie],
        delegate: focusedStore
      )
      .onChange(of: currentAccount.account?.id) {
        mainStore.currentAccount = currentAccount.account
        for p in followUpStores {
          p.currentAccount = mainStore.currentAccount
        }
      }
      .onChange(of: editorFocusState) { _, newValue in
        if let newValue {
          lastEditorFocusState = newValue
          if isMediaPanelPresented {
            isMediaPanelPresented = false
          }
        }
      }
      .onChange(of: isMediaPanelPresented) { _, newValue in
        if newValue {
          lastEditorFocusState = editorFocusState
          editorFocusState = nil
        } else if editorFocusState == nil {
          editorFocusState = lastEditorFocusState ?? .main
        }
      }
      .onChange(of: mainStore.visibility) {
        for p in followUpStores {
          p.visibility = mainStore.visibility
        }
      }
      .onChange(of: followUpStores.count) { oldValue, newValue in
        if oldValue < newValue {
          Task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.bouncy(duration: 0.5)) {
              scrollID = followUpStores.last?.id
            }
          }
        }
      }
    }

    private var editorStack: some View {
      VStackLayout(spacing: 0) {
        EditorView(
          store: mainStore,
          followUpStores: $followUpStores,
          editingMediaContainer: $editingMediaContainer,
          presentationDetent: $presentationDetent,
          editorFocusState: $editorFocusState,
          assignedFocusState: .main,
          isMain: true
        )
        .id(mainStore.id)

        ForEach(followUpStores) { store in
          @Bindable var store: EditorStore = store

          EditorView(
            store: store,
            followUpStores: $followUpStores,
            editingMediaContainer: $editingMediaContainer,
            presentationDetent: $presentationDetent,
            editorFocusState: $editorFocusState,
            assignedFocusState: .followUp(index: store.id),
            isMain: false
          )
          .id(store.id)
        }
      }
      .scrollTargetLayout()
    }

    @ViewBuilder
    private func bottomInset(focusedStore: EditorStore) -> some View {
      if presentationDetent == .large || presentationDetent == .medium {
        if #available(iOS 26.0, *) {
          GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
              AutoCompleteView(store: focusedStore)

              AccessoryView(
                focusedStore: focusedStore,
                followUpStores: $followUpStores,
                isMediaPanelPresented: $isMediaPanelPresented
              )
              .padding(.bottom, isMediaPanelPresented ? 0 : 8)

              if isMediaPanelPresented {
                MediaPickerPanelView(store: focusedStore)
              }
            }
          }
        } else {
          VStack(spacing: 0) {
            AutoCompleteView(store: focusedStore)

            AccessoryView(
              focusedStore: focusedStore,
              followUpStores: $followUpStores,
              isMediaPanelPresented: $isMediaPanelPresented)

            if isMediaPanelPresented {
              MediaPickerPanelView(store: focusedStore)
            }
          }
        }
      }
    }
  }
}
