import AVFoundation
import Models
import Nuke
import QuickLook
import SwiftUI

public struct MediaUIView: View, @unchecked Sendable {
  private let data: [DisplayData]
  private let initialItem: DisplayData?
  @State private var scrolledItem: DisplayData?
  @FocusState private var isFocused: Bool

  public var body: some View {
    NavigationStack {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(data) {
            DisplayView(data: $0)
              .containerRelativeFrame([.horizontal, .vertical])
              .id($0)
          }
        }
        .scrollTargetLayout()
      }
      .focusable()
      .focused($isFocused)
      .focusEffectDisabled()
      .onKeyPress(.leftArrow, action: {
        scrollToPrevious()
        return .handled
      })
      .onKeyPress(.rightArrow, action: {
        scrollToNext()
        return .handled
      })
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $scrolledItem)
      .toolbar {
        if let item = scrolledItem {
          MediaToolBar(data: item)
        }
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          scrolledItem = initialItem
          isFocused = true
        }
      }
    }
  }

  public init(selectedAttachment: MediaAttachment, attachments: [MediaAttachment]) {
    data = attachments.compactMap { DisplayData(from: $0) }
    initialItem = DisplayData(from: selectedAttachment)
  }

  private func scrollToPrevious() {
    if let scrolledItem, let index = data.firstIndex(of: scrolledItem), index > 0 {
      withAnimation {
        self.scrolledItem = data[index - 1]
      }
    }
  }

  private func scrollToNext() {
    if let scrolledItem, let index = data.firstIndex(of: scrolledItem), index < data.count - 1 {
      withAnimation {
        self.scrolledItem = data[index + 1]
      }
    }
  }
}

private struct MediaToolBar: ToolbarContent {
  let data: DisplayData

  var body: some ToolbarContent {
    DismissToolbarItem()
    QuickLookToolbarItem(itemUrl: data.url)
    AltTextToolbarItem(alt: data.description)
    SavePhotoToolbarItem(url: data.url, type: data.type)
    ShareToolbarItem(url: data.url, type: data.type)
  }
}

private struct DismissToolbarItem: ToolbarContent {
  @Environment(\.dismiss) private var dismiss

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle")
      }
      .opacity(0)
      .keyboardShortcut(.cancelAction)
    }
  }
}

private struct AltTextToolbarItem: ToolbarContent {
  let alt: String?
  @State private var isAlertDisplayed = false

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      if let alt {
        Button {
          isAlertDisplayed = true
        } label: {
          Text("status.image.alt-text.abbreviation")
        }
        .alert("status.editor.media.image-description",
               isPresented: $isAlertDisplayed)
        {
          Button("alert.button.ok", action: {})
        } message: {
          Text(alt)
        }
      } else {
        EmptyView()
      }
    }
  }
}

private struct SavePhotoToolbarItem: ToolbarContent, @unchecked Sendable {
  let url: URL
  let type: DisplayType
  @State private var state = SavingState.unsaved

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      if type == .image {
        Button {
          Task {
            state = .saving
            if await saveImage(url: url) {
              withAnimation {
                state = .saved
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                  state = .unsaved
                }
              }
            }
          }
        } label: {
          switch state {
          case .unsaved: Image(systemName: "arrow.down.circle")
          case .saving: ProgressView()
          case .saved: Image(systemName: "checkmark.circle.fill")
          }
        }
      } else {
        EmptyView()
      }
    }
  }

  private enum SavingState {
    case unsaved
    case saving
    case saved
  }

  private func imageData(_ url: URL) async -> Data? {
    var data = ImagePipeline.shared.cache.cachedData(for: .init(url: url))
    if data == nil {
      data = try? await URLSession.shared.data(from: url).0
    }
    return data
  }

  private func uiimageFor(url: URL) async throws -> UIImage? {
    let data = await imageData(url)
    if let data {
      return UIImage(data: data)
    }
    return nil
  }

  private func saveImage(url: URL) async -> Bool {
    if let image = try? await uiimageFor(url: url) {
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
      return true
    }
    return false
  }
}

private struct DisplayData: Identifiable, Hashable {
  let id: String
  let url: URL
  let description: String?
  let type: DisplayType

  init?(from attachment: MediaAttachment) {
    guard let url = attachment.url else { return nil }
    guard let type = attachment.supportedType else { return nil }

    id = attachment.id
    self.url = url
    description = attachment.description
    self.type = DisplayType(from: type)
  }
}

private struct DisplayView: View {
  let data: DisplayData

  var body: some View {
    switch data.type {
    case .image:
      MediaUIAttachmentImageView(url: data.url)
    case .av:
      MediaUIAttachmentVideoView(viewModel: .init(url: data.url, forceAutoPlay: true))
    }
  }
}
