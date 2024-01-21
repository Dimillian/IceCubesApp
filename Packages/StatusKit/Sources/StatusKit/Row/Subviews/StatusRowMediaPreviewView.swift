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
  @Environment(\.isMediaCompact) private var isCompact: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(SceneDelegate.self) private var sceneDelegate
  @Environment(UserPreferences.self) private var preferences
  @Environment(QuickLook.self) private var quickLook
  @Environment(Theme.self) private var theme

  public let attachments: [MediaAttachment]
  public let sensitive: Bool

  @State private var isQuickLookLoading: Bool = false

  init(attachments: [MediaAttachment], sensitive: Bool) {
    self.attachments = attachments
    self.sensitive = sensitive
  }

#if targetEnvironment(macCatalyst)
  private var showsScrollIndicators: Bool { attachments.count > 1 }
  private var scrollBottomPadding: CGFloat?
#else
  private var showsScrollIndicators: Bool = false
  private var scrollBottomPadding: CGFloat? = 0
#endif

  var availableWidth: CGFloat {
    #if os(visionOS)
      return sceneDelegate.windowWidth * 0.96
    #else
    if UIDevice.current.userInterfaceIdiom == .phone &&
      (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) || theme.statusDisplayStyle == .medium
    {
      return sceneDelegate.windowWidth * 0.80
    }
    return sceneDelegate.windowWidth
    #endif
  }

  var appLayoutWidth: CGFloat {
    let avatarColumnWidth = theme.avatarPosition == .leading ? AvatarView.FrameConfig.status.width + .statusColumnsSpacing : 0
    var sidebarWidth: CGFloat = 0
    var secondaryColumnWidth: CGFloat = 0
    let layoutPading: CGFloat = .layoutPadding * 2
    if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass != .compact {
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
    return 300
  }

  public var body: some View {
    Group {
      if attachments.count == 1 {
        FeaturedImagePreView(
          attachment: attachments[0],
          imageMaxHeight: imageMaxHeight,
          sensitive: sensitive,
          appLayoutWidth: appLayoutWidth,
          availableWidth: availableWidth,
          availableHeight: sceneDelegate.windowHeight
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(for: attachments[0]))
        .accessibilityAddTraits([.isButton, .isImage])
        .onTapGesture { tabAction(for: 0) }
      } else {
        ScrollView(.horizontal, showsIndicators: showsScrollIndicators) {
          HStack {
            makeAttachmentView(for: 0)
            makeAttachmentView(for: 1)
            makeAttachmentView(for: 2)
            makeAttachmentView(for: 3)
          }
          .padding(.bottom, scrollBottomPadding)
        }
        .scrollClipDisabled()
      }
    }
  }

  @ViewBuilder
  private func makeAttachmentView(for index: Int) -> some View {
    if
      attachments.count > index,
      let data = DisplayData(from: attachments[index])
    {
      MediaPreview(
        sensitive: sensitive,
        imageMaxHeight: imageMaxHeight,
        displayData: data
      )
      .onTapGesture { tabAction(for: index) }
    }
  }

  private func tabAction(for index: Int) {
    #if targetEnvironment(macCatalyst) || os(visionOS)
      openWindow(
        value: WindowDestinationMedia.mediaViewer(
          attachments: attachments,
          selectedAttachment: attachments[index]
        )
      )
    #else
      quickLook.prepareFor(
        selectedMediaAttachment: attachments[index],
        mediaAttachments: attachments
      )
    #endif
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
  let sensitive: Bool
  let imageMaxHeight: CGFloat
  let displayData: DisplayData

  @Environment(UserPreferences.self) private var preferences
  @Environment(\.isCompact) private var isCompact: Bool

  var body: some View {
    GeometryReader { _ in
      switch displayData.type {
      case .image:
        LazyResizableImage(url: displayData.previewUrl) { state, _ in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: displayData.isLandscape ? imageMaxHeight * 1.2 : imageMaxHeight / 1.5,
                     height: imageMaxHeight)
              .overlay(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray.opacity(0.35), lineWidth: 1)
              )
          } else if state.isLoading {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.gray)
          }
        }
        .overlay {
          BlurOverLay(sensitive: sensitive, font: .scaledFootnote)
        }
        .overlay {
          AltTextButton(text: displayData.description, font: .scaledFootnote)
        }
      case .av:
        MediaUIAttachmentVideoView(viewModel: .init(url: displayData.url))
          .accessibilityAddTraits(.startsMediaSession)
      }
    }
    .frame(width: displayData.isLandscape ? imageMaxHeight * 1.2 : imageMaxHeight / 1.5,
           height: imageMaxHeight)
    .clipped()
    .cornerRadius(4)
    // #965: do not create overlapping tappable areas, when multiple images are shown
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(displayData.accessibilityText))
    .accessibilityAddTraits(displayData.type == .image ? [.isImage, .isButton] : .isButton)
  }
}

@MainActor
private struct FeaturedImagePreView: View {
  let attachment: MediaAttachment
  let imageMaxHeight: CGFloat
  let sensitive: Bool
  let appLayoutWidth: CGFloat
  let availableWidth: CGFloat
  let availableHeight: CGFloat

  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(Theme.self) private var theme
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(\.isModal) private var isModal: Bool

  var body: some View {
    let size: CGSize = size(for: attachment) ?? .init(width: imageMaxHeight, height: imageMaxHeight)
    let newSize = imageSize(from: size)
    Group {
      switch attachment.supportedType {
      case .image:
        LazyImage(url: attachment.url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .overlay(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.gray.opacity(0.35), lineWidth: 1)
              )
          } else {
            RoundedRectangle(cornerRadius: 4).fill(Color.gray)
          }
        }
        .processors([.resize(size: newSize)])
      case .gifv, .video, .audio:
        if let url = attachment.url {
          MediaUIAttachmentVideoView(viewModel: .init(url: url))
        }
      case .none:
        EmptyView()
      }
    }
    .frame(width: newSize.width, height: newSize.height)
    .overlay {
      BlurOverLay(sensitive: sensitive, font: .scaledFootnote)
    }
    .overlay {
      AltTextButton(
        text: attachment.description,
        font: theme.statusDisplayStyle == .compact ? .footnote : .body
      )
    }
    .clipped()
    .cornerRadius(4)
  }

  private func size(for media: MediaAttachment) -> CGSize? {
    guard let width = media.meta?.original?.width,
          let height = media.meta?.original?.height
    else { return nil }

    guard width != 1 && height != 1 else {
      return .init(width: 800, height: 600)
    }
    
    return .init(width: CGFloat(width), height: CGFloat(height))
  }

  private func imageSize(from: CGSize) -> CGSize {
    if isCompact || theme.statusDisplayStyle == .compact || isSecondaryColumn {
      return .init(width: imageMaxHeight, height: imageMaxHeight)
    }

    var boxWidth = availableWidth - appLayoutWidth
    if isModal &&
        (UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac) {
      boxWidth = availableWidth * 0.50
    }
    let boxHeight = availableHeight * 0.8 // use only 80% of window height to leave room for text

    if from.width <= boxWidth, from.height <= boxHeight {
      // intrinsic size of image fits just fine
      return from
    }

    // shrink image proportionally to fit inside the box
    let xRatio = boxWidth / from.width
    let yRatio = boxHeight / from.height
    if xRatio < yRatio {
      return .init(width: boxWidth, height: from.height * xRatio)
    } else {
      return .init(width: from.width * yRatio, height: boxHeight)
    }
  }
}

@MainActor
struct BlurOverLay: View {
  let sensitive: Bool
  let font: Font?

  @State private var isFrameExpanded = true

  @Environment(Theme.self) private var theme
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(UserPreferences.self) private var preferences
  @Environment(\.isCompact) private var isCompact: Bool

  @Namespace var buttonSpace

  var body: some View {
    if hasOverlay {
      ZStack {
        Rectangle()
          .foregroundColor(.clear)
          .background(.ultraThinMaterial)
          .frame(
            width: isFrameExpanded ? nil : 0,
            height: isFrameExpanded ? nil : 0
          )
        if !isCompact {
          Button {
            withAnimation(.spring) {
              isFrameExpanded.toggle()
            }
          } label: {
            if isFrameExpanded {
              ViewThatFits(in: .horizontal) {
                HStack {
                  Image(systemName: "eye")
                    .matchedGeometryEffect(id: "eye", in: buttonSpace)
                  Text(sensitive ? "status.media.sensitive.show" : "status.media.content.show")
                }
                HStack {
                  Image(systemName: "eye")
                    .matchedGeometryEffect(id: "eye", in: buttonSpace)
                  Text("Show")
                }
                Image(systemName: "eye")
                  .matchedGeometryEffect(id: "eye", in: buttonSpace)
              }
              .lineLimit(1)
              .foregroundColor(theme.labelColor)
            } else {
              Image(systemName: "eye.slash")
                .transition(.opacity)
                .matchedGeometryEffect(id: "eye", in: buttonSpace)
            }
          }
          .foregroundColor(theme.labelColor)
          .buttonStyle(.borderedProminent)
          .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
        }
      }
      .font(font)
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

struct AltTextButton: View {
  let text: String?
  let font: Font?

  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(UserPreferences.self) private var preferences
  @Environment(\.locale) private var locale
  @Environment(Theme.self) private var theme

  @State private var isDisplayingAlert = false

  var body: some View {
    if !isInCaptureMode,
       let text,
       !text.isEmpty,
       !isCompact,
       preferences.showAltTextForMedia
    {
      Button {
        isDisplayingAlert = true
      } label: {
        ZStack {
          // use to sync button with show/hide content button
          Image(systemName: "eye.slash").opacity(0)
          Text("status.image.alt-text.abbreviation")
        }
      }
      .buttonStyle(.borderless)
      .padding(EdgeInsets(top: 5, leading: 7, bottom: 5, trailing: 7))
      .background(.thinMaterial)
      .cornerRadius(4)
      .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
      .alert(
        "status.editor.media.image-description",
        isPresented: $isDisplayingAlert
      ) {
        Button("alert.button.ok", action: {})
      } message: {
        Text(text)
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .bottomTrailing
      )
    }
  }
}

private struct DisplayData: Identifiable, Hashable {
  let id: String
  let url: URL
  let previewUrl: URL?
  let description: String?
  let type: DisplayType
  let accessibilityText: String
  let isLandscape: Bool

  init?(from attachment: MediaAttachment) {
    guard let url = attachment.url else { return nil }
    guard let type = attachment.supportedType else { return nil }

    id = attachment.id
    self.url = url
    previewUrl = attachment.previewUrl ?? attachment.url
    description = attachment.description
    self.type = DisplayType(from: type)
    accessibilityText = Self.getAccessibilityString(from: attachment)
    isLandscape = (attachment.meta?.original?.width ?? 0) > (attachment.meta?.original?.height ?? 0)
  }

  private static func getAccessibilityString(from attachment: MediaAttachment) -> String {
    if let altText = attachment.description {
      "accessibility.image.alt-text-\(altText)"
    } else if let typeDescription = attachment.localizedTypeDescription {
      typeDescription
    } else {
      "accessibility.tabs.profile.picker.media"
    }
  }
}

private enum DisplayType {
  case image
  case av

  init(from attachmentType: MediaAttachment.SupportedType) {
    switch attachmentType {
    case .image:
      self = .image
    case .video, .gifv, .audio:
      self = .av
    }
  }
}

struct StatusRowMediaPreviewView_Previews: PreviewProvider {
  static var previews: some View {
    WrapperForPreview()
  }
}

struct WrapperForPreview: View {
  @State private var isCompact = false
  @State private var isInCaptureMode = false

  var body: some View {
    VStack {
      ScrollView {
        VStack {
          ForEach(1 ..< 5) { number in
            VStack {
              Text("Preview for \(number) item(s)")
              StatusRowMediaPreviewView(
                attachments: Array(repeating: Self.attachment, count: number),
                sensitive: true
              )
            }
            .padding()
            .border(.red)
          }
        }
      }
      .environment(SceneDelegate())
      .environment(UserPreferences.shared)
      .environment(QuickLook.shared)
      .environment(Theme.shared)
      .environment(\.isCompact, isCompact)
      .environment(\.isInCaptureMode, isInCaptureMode)

      Divider()
      Toggle("Compact Mode", isOn: $isCompact.animation())
      Toggle("Capture Mode", isOn: $isInCaptureMode)
    }
    .padding()
  }

  private static let url = URL(string: "https://www.upwork.com/catalog-images/c5dffd9b5094556adb26e0a193a1c494")!
  private static let attachment = MediaAttachment.imageWith(url: url)
  private static let local = Locale(identifier: "en")
}
