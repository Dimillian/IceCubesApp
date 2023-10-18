import Foundation
import NukeUI
import Nuke
import SwiftUI
import Models
import QuickLook

public struct MediaUIView: View {
  @Environment(\.dismiss) private var dismiss
  
  public let selectedAttachment: MediaAttachment
  public let attachments: [MediaAttachment]
  
  @State private var scrollToId: String?
  @State private var altTextDisplayed: String?
  @State private var isAltAlertDisplayed: Bool = false
  @State private var quickLookURL: URL?
  
  @State private var isSavingPhoto: Bool = false
  @State private var didSavePhoto: Bool = false
  
  public init(selectedAttachment: MediaAttachment, attachments: [MediaAttachment]) {
    self.selectedAttachment = selectedAttachment
    self.attachments = attachments
  }

  public var body: some View {
    NavigationStack {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(attachments) { attachment in
            if let url = attachment.url {
              switch attachment.supportedType {
              case .image:
                MediaUIAttachmentImageView(url: url)
                  .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 0)
                  .id(attachment.id)
              case .video, .gifv, .audio:
                MediaUIAttachmentVideoView(viewModel: .init(url: url, forceAutoPlay: true))
                  .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 0)
                  .containerRelativeFrame(.vertical, count: 1, span: 1, spacing: 0)
                  .id(attachment.id)
              case .none:
                EmptyView()
              }
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $scrollToId)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark.circle")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if let url = attachments.first(where: { $0.id == scrollToId})?.url {
            Button {
              Task {
                quickLookURL = try? await localPathFor(url: url)
              }
            } label: {
              Image(systemName: "info.circle")
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if let alt = attachments.first(where: { $0.id == scrollToId})?.description {
            Button {
              altTextDisplayed = alt
              isAltAlertDisplayed = true
            } label: {
              Text("status.image.alt-text.abbreviation")
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if let attachment = attachments.first(where: { $0.id == scrollToId}),
             let url = attachment.url,
              attachment.supportedType == .image {
            Button {
              Task {
                isSavingPhoto = true
                if await saveImage(url: url) {
                  withAnimation {
                    isSavingPhoto = false
                    didSavePhoto = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                      didSavePhoto = false
                    }
                  }
                } else {
                  isSavingPhoto = false
                }
              }
            } label: {
              if isSavingPhoto {
                ProgressView()
              } else if didSavePhoto {
                Image(systemName: "checkmark.circle.fill")
              } else {
                Image(systemName: "arrow.down.circle")
              }
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          if let url = attachments.first(where: { $0.id == scrollToId})?.url {
            ShareLink(item: url)
          }
        }
      }
      .alert("status.editor.media.image-description",
             isPresented: $isAltAlertDisplayed)
      {
        Button("alert.button.ok", action: {})
      } message: {
        Text(altTextDisplayed ?? "")
      }
      .quickLookPreview($quickLookURL)
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          scrollToId = selectedAttachment.id
        }
      }
    }
  }
  
  
  private var quickLookDir: URL {
    try! FileManager.default.url(for: .cachesDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: false)
    .appending(component: "quicklook")
  }
  
  private func localPathFor(url: URL) async throws -> URL {
    try? FileManager.default.removeItem(at: quickLookDir)
    try? FileManager.default.createDirectory(at: quickLookDir, withIntermediateDirectories: true)
    let path = quickLookDir.appendingPathComponent(url.lastPathComponent)
    var data = ImagePipeline.shared.cache.cachedData(for: .init(url: url))
    if data == nil {
      data = try await URLSession.shared.data(from: url).0
    }
    try data?.write(to: path)
    return path
  }
  
  private func uiimageFor(url: URL) async throws -> UIImage? {
    var data = ImagePipeline.shared.cache.cachedData(for: .init(url: url))
    if data == nil {
      data = try await URLSession.shared.data(from: url).0
    }
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
