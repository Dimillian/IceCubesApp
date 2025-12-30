import DesignSystem
import Env
import PhotosUI
import SwiftUI

extension StatusEditor {
  @MainActor
  struct AccessoryView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let focusedStore: EditorStore
    @Binding var followUpStores: [EditorStore]
    @Binding var isMediaPanelPresented: Bool

    @State private var isCustomEmojisSheetDisplay: Bool = false
    @State private var isLoadingAIRequest: Bool = false
    #if os(visionOS)
      @State private var isPhotosPickerPresented: Bool = false
      @State private var isFileImporterPresented: Bool = false
      @State private var isCameraPickerPresented: Bool = false
    #endif
    var body: some View {
      @Bindable var store = focusedStore
      #if os(visionOS)
        HStack {
          contentView
            .buttonStyle(.borderless)
        }
        .frame(width: 32)
        .padding(16)
        .glassBackgroundEffect()
        .cornerRadius(8)
        .padding(.trailing, 78)
      #else
        if #available(iOS 26, *) {
          contentView
            .padding(.vertical, 16)
            .glassEffect(.regular)
            .background(theme.primaryBackgroundColor.opacity(0.2))
            .padding(.horizontal, 16)
        } else {
          HStack {
            contentView
          }
          .frame(height: 20)
          .padding(.vertical, 12)
          .background(.ultraThickMaterial)
        }
      #endif
    }

    @ViewBuilder
    private var contentView: some View {
      #if os(visionOS)
        VStack(spacing: 8) {
          actionsView
        }
      #else
        ViewThatFits {
          HStack(alignment: .center, spacing: 16) {
            actionsView
          }
          .padding(.horizontal, .layoutPadding)

          ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 16) {
              actionsView
            }
            .padding(.horizontal, .layoutPadding)
          }
          .scrollIndicators(.hidden)
        }
      #endif
    }

    @ViewBuilder
    private var actionsView: some View {
      @Bindable var store = focusedStore
      #if os(visionOS)
        Menu {
          Button {
            isPhotosPickerPresented = true
          } label: {
            Label("status.editor.photo-library", systemImage: "photo")
              .frame(width: 25, height: 25)
              .contentShape(Rectangle())
          }
          Button {
            isCameraPickerPresented = true
          } label: {
            Label("status.editor.camera-picker", systemImage: "camera")
          }
          Button {
            isFileImporterPresented = true
          } label: {
            Label("status.editor.browse-file", systemImage: "folder")
          }
        } label: {
          if store.isMediasLoading {
            ProgressView()
          } else {
            Image(systemName: "photo.on.rectangle.angled")
              .frame(width: 25, height: 25)
              .contentShape(Rectangle())
              .foregroundStyle(theme.tintColor)
          }
        }
        .buttonStyle(.plain)
        .photosPicker(
          isPresented: $isPhotosPickerPresented,
          selection: $store.mediaPickers,
          maxSelectionCount: currentInstance.instance?.configuration?.statuses.maxMediaAttachments
            ?? 4,
          matching: .any(of: [.images, .videos]),
          photoLibrary: .shared()
        )
        .fileImporter(
          isPresented: $isFileImporterPresented,
          allowedContentTypes: [.image, .video, .movie],
          allowsMultipleSelection: true
        ) { result in
          if let urls = try? result.get() {
            store.processURLs(urls: urls)
          }
        }
        .fullScreenCover(
          isPresented: $isCameraPickerPresented,
          content: {
            CameraPickerView(
              selectedImage: .init(
                get: {
                  nil
                },
                set: { image in
                  if let image {
                    store.processCameraPhoto(image: image)
                  }
                })
            )
            .background(.black)
          }
        )
        .accessibilityLabel("accessibility.editor.button.attach-photo")
        .disabled(store.showPoll)
      #else
        Button {
          isMediaPanelPresented.toggle()
        } label: {
          if store.isMediasLoading {
            ProgressView()
          } else {
            Image(systemName: isMediaPanelPresented ? "xmark" : "photo.on.rectangle.angled")
              .frame(width: 25, height: 25)
              .contentShape(Rectangle())
              .foregroundStyle(theme.tintColor)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("accessibility.editor.button.attach-photo")
        .disabled(store.showPoll)
      #endif

      Button {
        // all stores have the same visibility value
        followUpStores.append(focusedStore.makeFollowUpStore())
      } label: {
        Image(systemName: "arrowshape.turn.up.left.circle.fill")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }
      .disabled(!canAddNewStore)

      if !store.customEmojiContainer.isEmpty {
        Button {
          isCustomEmojisSheetDisplay = true
        } label: {
          // This is a workaround for an apparent bug in the `face.smiling` SF Symbol.
          // See https://github.com/Dimillian/IceCubesApp/issues/1193
          let customEmojiSheetIconName =
            colorScheme == .light ? "face.smiling" : "face.smiling.inverse"
          Image(systemName: customEmojiSheetIconName)
            .frame(width: 25, height: 25)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("accessibility.editor.button.custom-emojis")
        .sheet(isPresented: $isCustomEmojisSheetDisplay) {
          CustomEmojisView(store: focusedStore)
            .environment(theme)
        }
      }

      if #available(iOS 26, *), Assistant.isAvailable {
        AssistantMenu.disabled(!store.canPost)
      }

      Spacer()

      Button {
        store.insertStatusText(text: "@")
      } label: {
        Image(systemName: "at")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }

      Button {
        store.insertStatusText(text: "#")
      } label: {
        Image(systemName: "number")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }
    }

    private var canAddNewStore: Bool {
      guard followUpStores.count < 5 else { return false }

      if followUpStores.isEmpty,  // there is only the main store in the editor
        !focusedStore.statusText.string.isEmpty  // focusedStore is also mainStore
      {
        return true
      }

      if let lastStore = followUpStores.last,
        !lastStore.statusText.string.isEmpty
      {
        return true
      }

      return false
    }

    @available(iOS 26, *)
    private var AssistantMenu: some View {
      Menu {
        ForEach(AIPrompt.allCases, id: \.self) { prompt in
          if case AIPrompt.rewriteWithTone = prompt {
            Menu {
              ForEach(Assistant.Tone.allCases, id: \.self) { tone in
                Button {
                  isLoadingAIRequest = true
                  Task {
                    await focusedStore.runAssistant(prompt: prompt)
                    isLoadingAIRequest = false
                  }
                } label: {
                  tone.label
                }
              }
            } label: {
              prompt.label
            }
          } else {
            Button {
              isLoadingAIRequest = true
              Task {
                await focusedStore.runAssistant(prompt: prompt)
                isLoadingAIRequest = false
              }
            } label: {
              prompt.label
            }
          }
        }
        if let backup = focusedStore.backupStatusText {
          Button {
            focusedStore.replaceTextWith(text: backup.string)
            focusedStore.backupStatusText = nil
          } label: {
            Label("status.editor.restore-previous", systemImage: "arrow.uturn.right")
          }
        }
      } label: {
        if isLoadingAIRequest {
          ProgressView()
        } else {
          Image(systemName: "faxmachine")
            .accessibilityLabel("accessibility.editor.button.ai-prompt")
            .foregroundStyle(focusedStore.canPost ? theme.tintColor : .secondary)
            .frame(width: 25, height: 25)
            .contentShape(Rectangle())
        }
      }
      .buttonStyle(.plain)
    }
  }
}
