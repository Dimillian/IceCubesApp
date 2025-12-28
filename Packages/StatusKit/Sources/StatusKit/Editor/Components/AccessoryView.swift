import DesignSystem
import Env
import PhotosUI
import SwiftUI

extension StatusEditor {
  @MainActor
  struct AccessoryView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let focusedSEVM: ViewModel
    @Binding var followUpSEVMs: [ViewModel]
    @Binding var isMediaPanelPresented: Bool

    @State private var isCustomEmojisSheetDisplay: Bool = false
    @State private var isLoadingAIRequest: Bool = false
    #if os(visionOS)
      @State private var isPhotosPickerPresented: Bool = false
      @State private var isFileImporterPresented: Bool = false
      @State private var isCameraPickerPresented: Bool = false
    #endif
    var body: some View {
      @Bindable var viewModel = focusedSEVM
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
      @Bindable var viewModel = focusedSEVM
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
          if viewModel.isMediasLoading {
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
          selection: $viewModel.mediaPickers,
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
            viewModel.processURLs(urls: urls)
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
                    viewModel.processCameraPhoto(image: image)
                  }
                })
            )
            .background(.black)
          }
        )
        .accessibilityLabel("accessibility.editor.button.attach-photo")
        .disabled(viewModel.showPoll)
      #else
        Button {
          isMediaPanelPresented.toggle()
        } label: {
          if viewModel.isMediasLoading {
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
        .disabled(viewModel.showPoll)
      #endif

      Button {
        // all SEVM have the same visibility value
        followUpSEVMs.append(ViewModel(mode: .new(text: nil, visibility: focusedSEVM.visibility)))
      } label: {
        Image(systemName: "arrowshape.turn.up.left.circle.fill")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }
      .disabled(!canAddNewSEVM)

      if !viewModel.customEmojiContainer.isEmpty {
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
          CustomEmojisView(viewModel: focusedSEVM)
            .environment(theme)
        }
      }

      if #available(iOS 26, *), Assistant.isAvailable {
        AssistantMenu.disabled(!viewModel.canPost)
      }

      Spacer()

      Button {
        viewModel.insertStatusText(text: "@")
      } label: {
        Image(systemName: "at")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }

      Button {
        viewModel.insertStatusText(text: "#")
      } label: {
        Image(systemName: "number")
          .frame(width: 25, height: 25)
          .contentShape(Rectangle())
      }
    }

    private var canAddNewSEVM: Bool {
      guard followUpSEVMs.count < 5 else { return false }

      if followUpSEVMs.isEmpty,  // there is only mainSEVM on the editor
        !focusedSEVM.statusText.string.isEmpty  // focusedSEVM is also mainSEVM
      {
        return true
      }

      if let lastSEVMs = followUpSEVMs.last,
        !lastSEVMs.statusText.string.isEmpty
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
                    await focusedSEVM.runAssistant(prompt: prompt)
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
                await focusedSEVM.runAssistant(prompt: prompt)
                isLoadingAIRequest = false
              }
            } label: {
              prompt.label
            }
          }
        }
        if let backup = focusedSEVM.backupStatusText {
          Button {
            focusedSEVM.replaceTextWith(text: backup.string)
            focusedSEVM.backupStatusText = nil
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
            .foregroundStyle(focusedSEVM.canPost ? theme.tintColor : .secondary)
            .frame(width: 25, height: 25)
            .contentShape(Rectangle())
        }
      }
      .buttonStyle(.plain)
    }
  }
}
