import DesignSystem
import Env
import Models
import Nuke
import NukeUI
import SwiftUI

public struct StatusRowMediaPreviewView: View {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.extraLeadingInset) private var extraLeadingInset: CGFloat
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isCompact) private var isCompact: Bool

  @EnvironmentObject var sceneDelegate: SceneDelegate
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var theme: Theme

  public let attachments: [MediaAttachment]
  public let sensitive: Bool

  @State private var isQuickLookLoading: Bool = false
  @State private var altTextDisplayed: String?
  @State private var isAltAlertDisplayed: Bool = false
  @State private var isHidingMedia: Bool = false

  var availableWidth: CGFloat {
    if UIDevice.current.userInterfaceIdiom == .phone &&
      (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) || theme.statusDisplayStyle == .medium
    {
      return sceneDelegate.windowWidth * 0.80
    }
    return sceneDelegate.windowWidth
  }

  var appLayoutWidth: CGFloat {
    let avatarColumnWidth = theme.avatarPosition == .leading ? AvatarView.Size.status.size.width + .statusColumnsSpacing : 0
    var sidebarWidth: CGFloat = 0
    var secondaryColumnWidth: CGFloat = 0
    let layoutPading: CGFloat = .layoutPadding * 2
    if UIDevice.current.userInterfaceIdiom == .pad {
      sidebarWidth = .sidebarWidth
      if preferences.showiPadSecondaryColumn {
        secondaryColumnWidth = .secondaryColumnWidth
      }
    }
    return layoutPading + avatarColumnWidth + sidebarWidth + extraLeadingInset + secondaryColumnWidth
  }

  private var imageMaxHeight: CGFloat {
    if isCompact {
      return 50
    }
    if theme.statusDisplayStyle == .compact {
      if attachments.count == 1 {
        return 200
      }
      return 100
    }
    if attachments.count == 1 {
      return 300
    }
    return attachments.count > 2 ? 150 : 200
  }

  private func size(for media: MediaAttachment) -> CGSize? {
    if let width = media.meta?.original?.width,
       let height = media.meta?.original?.height
    {
      return .init(width: CGFloat(width), height: CGFloat(height))
    }
    return nil
  }

  private func imageSize(from: CGSize, newWidth: CGFloat) -> CGSize {
    if isCompact || theme.statusDisplayStyle == .compact || isSecondaryColumn {
      return .init(width: imageMaxHeight, height: imageMaxHeight)
    }
    let ratio = newWidth / from.width
    let newHeight = from.height * ratio
    return .init(width: newWidth, height: newHeight)
  }

  public var body: some View {
    Group {
      if attachments.count == 1, let attachment = attachments.first {
        makeFeaturedImagePreview(attachment: attachment)
          .onTapGesture {
            Task {
              await quickLook.prepareFor(urls: attachments.compactMap { $0.url }, selectedURL: attachment.url!)
            }
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(Self.accessibilityLabel(for: attachment))
          .accessibilityAddTraits([.isButton, .isImage])
      } else {
        if isCompact || theme.statusDisplayStyle == .compact {
          HStack {
            makeAttachmentView(for: 0)
            makeAttachmentView(for: 1)
            makeAttachmentView(for: 2)
            makeAttachmentView(for: 3)
          }
        } else {
          VStack {
            HStack {
              makeAttachmentView(for: 0)
              makeAttachmentView(for: 1)
            }
            HStack {
              makeAttachmentView(for: 2)
              makeAttachmentView(for: 3)
            }
          }
        }
      }
    }
    .overlay {
      if quickLook.isPreparing {
        quickLookLoadingView
          .transition(.opacity)
      }

      if isHidingMedia {
        sensitiveMediaOverlay
          .transition(.opacity)
      }
    }
    .alert("status.editor.media.image-description",
           isPresented: $isAltAlertDisplayed)
    {
      Button("alert.button.ok", action: {})
    } message: {
      Text(altTextDisplayed ?? "")
    }
    .onAppear {
      if sensitive && preferences.autoExpandMedia == .hideSensitive {
        isHidingMedia = true
      } else if preferences.autoExpandMedia == .hideAll {
        isHidingMedia = true
      } else {
        isHidingMedia = false
      }
    }
  }

  @ViewBuilder
  private func makeAttachmentView(for index: Int) -> some View {
    if attachments.count > index {
      makePreview(attachment: attachments[index])
    }
  }

  @ViewBuilder
  private func makeFeaturedImagePreview(attachment: MediaAttachment) -> some View {
    ZStack(alignment: .bottomLeading) {
      let size: CGSize = size(for: attachment) ?? .init(width: imageMaxHeight, height: imageMaxHeight)
      let newSize = imageSize(from: size, newWidth: availableWidth - appLayoutWidth)
      switch attachment.supportedType {
      case .image:
        LazyImage(url: attachment.url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: newSize.width, height: newSize.height)
              .clipped()
              .cornerRadius(4)
          } else {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.gray)
              .frame(width: newSize.width, height: newSize.height)
          }
        }
        .processors([.resize(size: newSize)])
        .frame(width: newSize.width, height: newSize.height)

      case .gifv, .video, .audio:
        if let url = attachment.url {
          VideoPlayerView(viewModel: .init(url: url))
            .frame(width: newSize.width, height: newSize.height)
        }
      case .none:
        EmptyView()
      }
      if !isInCaptureMode, sensitive {
        cornerSensitiveButton
      }
      if !isInCaptureMode, let alt = attachment.description, !alt.isEmpty, !isCompact, preferences.showAltTextForMedia {
        Group {
          Button {
            altTextDisplayed = alt
            isAltAlertDisplayed = true
          } label: {
            Text("status.image.alt-text.abbreviation")
              .font(theme.statusDisplayStyle == .compact ? .footnote : .body)
          }
          .buttonStyle(.borderless)
          .padding(4)
          .background(.thinMaterial)
          .cornerRadius(4)
        }
        .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
      }
    }
  }

  @ViewBuilder
  private func makePreview(attachment: MediaAttachment) -> some View {
    if let type = attachment.supportedType, !isInCaptureMode {
      Group {
        GeometryReader { proxy in
          switch type {
          case .image:
            let width = isCompact ? imageMaxHeight : proxy.frame(in: .local).width
            let processors: [ImageProcessing] = [.resize(size: .init(width: width, height: imageMaxHeight))]
            ZStack(alignment: .bottomTrailing) {
              LazyImage(url: attachment.previewUrl ?? attachment.url) { state in
                if let image = state.image {
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: width)
                    .frame(maxHeight: imageMaxHeight)
                    .clipped()
                    .cornerRadius(4)
                } else if state.isLoading {
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(maxHeight: imageMaxHeight)
                    .frame(maxWidth: width)
                }
              }
              .processors(processors)
              if sensitive, !isInCaptureMode {
                cornerSensitiveButton
              }
              if !isInCaptureMode,
                 let alt = attachment.description,
                 !alt.isEmpty,
                 !isCompact,
                 preferences.showAltTextForMedia
              {
                Button {
                  altTextDisplayed = alt
                  isAltAlertDisplayed = true
                } label: {
                  Text("status.image.alt-text.abbreviation")
                    .font(.scaledFootnote)
                }
                .buttonStyle(.borderless)
                .padding(4)
                .background(.thinMaterial)
                .cornerRadius(4)
              }
            }
          case .gifv, .video, .audio:
            if let url = attachment.url {
              VideoPlayerView(viewModel: .init(url: url))
                .frame(width: isCompact ? imageMaxHeight : proxy.frame(in: .local).width)
                .frame(height: imageMaxHeight)
                .accessibilityAddTraits(.startsMediaSession)
            }
          }
        }
        .frame(maxWidth: isCompact ? imageMaxHeight : nil)
        .frame(height: imageMaxHeight)
      }
      // #965: do not create overlapping tappable areas, when multiple images are shown
      .contentShape(Rectangle())
      .onTapGesture {
        Task {
          await quickLook.prepareFor(urls: attachments.compactMap { $0.url }, selectedURL: attachment.url!)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Self.accessibilityLabel(for: attachment))
      .accessibilityAddTraits(attachment.supportedType == .image ? [.isImage, .isButton] : .isButton)
    }
  }

  private var quickLookLoadingView: some View {
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
    .background(.ultraThinMaterial)
  }

  private var sensitiveMediaOverlay: some View {
    ZStack {
      Rectangle()
        .foregroundColor(.clear)
        .background(.ultraThinMaterial)
      if !isCompact {
        Button {
          withAnimation {
            isHidingMedia = false
          }
        } label: {
          Group {
            if sensitive {
              Label("status.media.sensitive.show", systemImage: "eye")
            } else {
              Label("status.media.content.show", systemImage: "eye")
            }
          }
          .foregroundColor(theme.labelColor)
        }
        .buttonStyle(.borderedProminent)
      }
    }
  }

  private var cornerSensitiveButton: some View {
    HStack {
      Button {
        withAnimation {
          isHidingMedia = true
        }
      } label: {
        Image(systemName: "eye.slash")
          .frame(minHeight: 21) // Match the alt button in case it is also present
      }
      .padding(10)
      .buttonStyle(.borderedProminent)
      Spacer()
    }
  }

  private static func accessibilityLabel(for attachment: MediaAttachment) -> Text {
    if let altText = attachment.description {
      return Text("accessibility.image.alt-text-\(altText)")
    } else if let typeDescription = attachment.localizedTypeDescription {
      return Text(typeDescription)
    } else {
      return Text("accessibility.tabs.profile.picker.media")
    }
  }
}
