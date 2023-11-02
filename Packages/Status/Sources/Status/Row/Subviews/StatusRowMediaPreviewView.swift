import DesignSystem
import Env
import MediaUI
import Models
import Nuke
import NukeUI
import SwiftUI

@MainActor
public struct StatusRowMediaPreviewView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.extraLeadingInset) private var extraLeadingInset: CGFloat
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(SceneDelegate.self) private var sceneDelegate
  @Environment(UserPreferences.self) private var preferences
  @Environment(QuickLook.self) private var quickLook
  @Environment(Theme.self) private var theme

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

  public var body: some View {
    Group {
      if attachments.count == 1, let attachment = attachments.first {
        FeaturedImagePreView(
          attachment: attachment,
          imageMaxHeight: imageMaxHeight,
          sensitive: sensitive,
          isCompact: isCompact,
          appLayoutWidth: appLayoutWidth,
          availableWidth: availableWidth,
          preferences: preferences,
          isHidingMedia: $isHidingMedia,
          altTextDisplayed: altTextDisplayed,
          isAltAlertDisplayed: isAltAlertDisplayed
        )
        .onTapGesture {
          if ProcessInfo.processInfo.isMacCatalystApp {
            openWindow(
              value: WindowDestination.mediaViewer(
                attachments: attachments,
                selectedAttachment: attachment
              )
            )
          } else {
            quickLook.prepareFor(
              selectedMediaAttachment: attachment,
              mediaAttachments: attachments
            )
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
      MediaOverLay(
        isCompact: isCompact,
        sensitive: sensitive,
        labelColor: theme.labelColor,
        isHidingMedia: isHidingMedia
      )
    }
    .alert("status.editor.media.image-description",
           isPresented: $isAltAlertDisplayed)
    {
      Button("alert.button.ok", action: {})
    } message: {
      Text(altTextDisplayed ?? "")
    }
    .onAppear {
      if sensitive, preferences.autoExpandMedia == .hideSensitive {
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
      MediaPreview(
        isCompact: isCompact,
        sensitive: sensitive,
        imageMaxHeight: imageMaxHeight,
        attachment: attachments[index], 
        preferences: preferences, 
        altTextDisplayed: altTextDisplayed,
        isAltAlertDisplayed: isAltAlertDisplayed,
        isHidingMedia: $isHidingMedia
      )
      .onTapGesture {
        if ProcessInfo.processInfo.isMacCatalystApp {
          openWindow(
            value: WindowDestination.mediaViewer(
              attachments: attachments,
              selectedAttachment: attachments[index]
            )
          )
        } else {
          quickLook.prepareFor(
            selectedMediaAttachment: attachments[index],
            mediaAttachments: attachments
          )
        }
      }
    }
  }

  private static func accessibilityLabel(for attachment: MediaAttachment) -> Text {
    if let altText = attachment.description {
      Text("accessibility.image.alt-text-\(altText)")
    } else if let typeDescription = attachment.localizedTypeDescription {
      Text(typeDescription)
    } else {
      Text("accessibility.tabs.profile.picker.media")
    }
  }
}

private struct MediaPreview: View {
  let isCompact: Bool
  let sensitive: Bool
  let imageMaxHeight: CGFloat
  let attachment: MediaAttachment
  let preferences: UserPreferences

  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool

  @State var altTextDisplayed: String?
  @State var isAltAlertDisplayed: Bool
  @Binding var isHidingMedia: Bool

  var body: some View {
    if let type = attachment.supportedType, !isInCaptureMode {
      Group {
        GeometryReader { proxy in
          switch type {
          case .image:
            ZStack(alignment: .bottomTrailing) {
              LazyResizableImage(url: attachment.previewUrl ?? attachment.url) { state, proxy in
                let width = isCompact ? imageMaxHeight : proxy.frame(in: .local).width
                if let image = state.image {
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: width, maxHeight: imageMaxHeight)
                    .clipped()
                    .cornerRadius(4)
                    .overlay(
                      RoundedRectangle(cornerRadius: 4)
                        .stroke(.gray.opacity(0.35), lineWidth: 1)
                    )
                } else if state.isLoading {
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(maxWidth: width, maxHeight: imageMaxHeight)
                }
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
              MediaUIAttachmentVideoView(viewModel: .init(url: url))
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
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityAddTraits(attachment.supportedType == .image ? [.isImage, .isButton] : .isButton)
    }
  }

  private var accessibilityLabel: Text {
    if let altText = attachment.description {
      Text("accessibility.image.alt-text-\(altText)")
    } else if let typeDescription = attachment.localizedTypeDescription {
      Text(typeDescription)
    } else {
      Text("accessibility.tabs.profile.picker.media")
    }
  }
}

private struct FeaturedImagePreView: View {
  let attachment: MediaAttachment
  let imageMaxHeight: CGFloat
  let sensitive: Bool
  let isCompact: Bool
  let appLayoutWidth: CGFloat
  let availableWidth: CGFloat
  let preferences: UserPreferences

//  @Environment(UserPreferences.self) private var preferences
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(Theme.self) private var theme
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool

  @Binding var isHidingMedia: Bool
  @State var altTextDisplayed: String?
  @State var isAltAlertDisplayed: Bool = false

  var body: some View {
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
              .overlay(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray.opacity(0.35), lineWidth: 1)
              )
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
          MediaUIAttachmentVideoView(viewModel: .init(url: url))
            .frame(width: newSize.width, height: newSize.height)
        }
      case .none:
        EmptyView()
      }
      if !isInCaptureMode,
          let alt = attachment.description,
         !alt.isEmpty,
         !isCompact,
         preferences.showAltTextForMedia
      {
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
}

@MainActor
struct MediaOverLay: View {
  let isCompact: Bool
  let sensitive: Bool
  let labelColor: Color
  let isHidingMedia: Bool

  @State private var isFrameExpanded = true
  @State private var isTextExpanded = true
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(UserPreferences.self) private var preferences
  @Namespace var buttonSpace

  var body: some View {
    if hasOverlay {
      ZStack {
        Rectangle()
          .foregroundColor(.clear)
          .background(.ultraThinMaterial)
          .frame(
            width: isFrameExpanded ? nil : 0,
            height: isFrameExpanded ? nil : 0)
        if !isCompact {
          Button {
            withAnimation(.spring(duration: 0.2)) {
              isTextExpanded.toggle()
            } completion: {
              withAnimation(.spring(duration: 0.3)) {
                isFrameExpanded.toggle()
              }
            }
          } label: {
            if isTextExpanded {
              Group {
                if sensitive {
                  Label("status.media.sensitive.show", systemImage: "eye")
                } else {
                  Label("status.media.content.show", systemImage: "eye")
                }
              }
              .foregroundColor(labelColor)
              .matchedGeometryEffect(id: "text", in: buttonSpace)
            } else {
              Image(systemName: "eye.slash")
                .matchedGeometryEffect(id: "text", in: buttonSpace)
            }
          }
          .foregroundColor(labelColor)
          .buttonStyle(.borderedProminent)
          .padding(10)
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: isFrameExpanded ? .center : .bottomLeading
      )
    } else {
      EmptyView()
    }
  }

  private var hasOverlay: Bool {
    switch (sensitive, preferences.autoExpandMedia) {
    case (_, .hideAll), (true, .hideSensitive):
      switch isInCaptureMode {
      case true: false
      case false: true
      }
    default: false
    }
  }
}
