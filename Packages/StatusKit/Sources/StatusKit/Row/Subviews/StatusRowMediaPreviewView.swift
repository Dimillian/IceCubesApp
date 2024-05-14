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
  @Environment(\.isMediaCompact) private var isCompact: Bool
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
          maxSize: imageMaxHeight == 300
            ? nil
            : CGSize(width: imageMaxHeight, height: imageMaxHeight),
          sensitive: sensitive
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(for: attachments[0]))
        .accessibilityAddTraits([.isButton, .isImage])
        .onTapGesture { tabAction(for: 0) }
      } else {
        ScrollView(.horizontal, showsIndicators: showsScrollIndicators) {
          HStack {
            ForEach(attachments) { attachment in
              makeAttachmentView(attachment)
            }
          }
          .padding(.bottom, scrollBottomPadding)
        }
        .scrollClipDisabled()
      }
    }
  }

  @ViewBuilder
  private func makeAttachmentView(_ attachement: MediaAttachment) -> some View {
    if let data = DisplayData(from: attachement) {
      MediaPreview(
        sensitive: sensitive,
        imageMaxHeight: imageMaxHeight,
        displayData: data
      )
      .onTapGesture {
        if let index = attachments.firstIndex(where: { $0.id == attachement.id }) {
          tabAction(for: index)
        }
      }
      #if os(visionOS)
      .hoverEffect()
      #endif
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

  var body: some View {
    Group {
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
                RoundedRectangle(cornerRadius: 10)
                  .stroke(.gray.opacity(0.35), lineWidth: 1)
              )
          } else if state.isLoading {
            RoundedRectangle(cornerRadius: 10)
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
    .cornerRadius(10)
    // #965: do not create overlapping tappable areas, when multiple images are shown
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(displayData.accessibilityText))
    .accessibilityAddTraits(displayData.type == .image ? [.isImage, .isButton] : .isButton)
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
  @Environment(\.isMediaCompact) private var isCompact: Bool

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
              .foregroundColor(theme.contrastingTintColor)
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
  @Environment(\.isMediaCompact) private var isCompact: Bool
  @Environment(UserPreferences.self) private var preferences
  @Environment(\.locale) private var locale
  @Environment(Theme.self) private var theme

  @State private var isDisplayingAlert = false
  @State private var isDisplayingTranslation = false

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
      #if canImport(_Translation_SwiftUI)
      .addTranslateView(isPresented: $isDisplayingTranslation, text: text)
      #endif
      #if os(visionOS)
        .clipShape(Capsule())
      #endif
        .cornerRadius(4)
        .padding(theme.statusDisplayStyle == .compact ? 0 : 10)
        .alert(
          "status.editor.media.image-description",
          isPresented: $isDisplayingAlert
        ) {
          Button("alert.button.ok", action: {})
          Button("status.action.copy-text", action: { UIPasteboard.general.string = text })
          #if canImport(_Translation_SwiftUI)
          if #available(iOS 17.4, *) {
            Button("status.action.translate", action: { isDisplayingTranslation = true })
          }
          #endif
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
      .environment(\.isMediaCompact, isCompact)
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

@MainActor
private struct FeaturedImagePreView: View {
  let attachment: MediaAttachment
  let maxSize: CGSize?
  let sensitive: Bool

  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(Theme.self) private var theme
  @Environment(\.isModal) private var isModal: Bool

  private var originalWidth: CGFloat {
    CGFloat(attachment.meta?.original?.width ?? 300)
  }

  private var originalHeight: CGFloat {
    CGFloat(attachment.meta?.original?.height ?? 300)
  }

  var body: some View {
    if let url = attachment.url {
      _Layout(originalWidth: originalWidth, originalHeight: originalHeight, maxSize: maxSize) {
        Group {
          RoundedRectangle(cornerRadius: 10).fill(Color.gray)
            .overlay {
              switch attachment.supportedType {
              case .image:
                LazyResizableImage(url: attachment.url) { state, _ in
                  if let image = state.image {
                    image
                      .resizable()
                      .scaledToFill()
                  } else {
                    RoundedRectangle(cornerRadius: 10).fill(Color.gray)
                  }
                }
              case .gifv, .video, .audio:
                MediaUIAttachmentVideoView(viewModel: .init(url: url))
              default:
                EmptyView()
              }
            }
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(.gray.opacity(0.35), lineWidth: 1)
            )
          #if os(visionOS)
            .hoverEffect()
          #endif
        }
      }
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
      .cornerRadius(10)
    }
  }

  private struct _Layout: Layout {
    let originalWidth: CGFloat
    let originalHeight: CGFloat
    let maxSize: CGSize?

    init(originalWidth: CGFloat?, originalHeight: CGFloat?, maxSize: CGSize?) {
      self.originalWidth = originalWidth ?? 200
      self.originalHeight = originalHeight ?? 200
      self.maxSize = maxSize
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
      guard !subviews.isEmpty else { return CGSize.zero }

      if let maxSize { return maxSize }

      return calculateSize(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
      guard let view = subviews.first else { return }

      let size = if let maxSize { maxSize } else { calculateSize(proposal) }
      view.place(at: bounds.origin, proposal: ProposedViewSize(size))
    }

    private func calculateSize(_ proposal: ProposedViewSize) -> CGSize {
      var size: CGSize
      switch (proposal.width, proposal.height) {
      case (0, _), (_, 0):
        size = CGSize.zero

      case (nil, nil), (nil, .some(.infinity)), (.some(.infinity), .some(.infinity)), (.some(.infinity), nil):
        size = CGSize(width: originalWidth, height: originalWidth)

      case let (nil, .some(height)), let (.some(.infinity), .some(height)):
        let minHeight = min(height, originalWidth)
        if originalHeight == 0 {
          size = CGSize.zero
        } else {
          size = CGSize(width: originalWidth * minHeight / originalHeight, height: minHeight)
        }

      case let (.some(width), .some(.infinity)), let (.some(width), nil):
        if originalWidth == 0 {
          size = CGSize(width: width, height: width)
        } else {
          size = CGSize(width: width, height: width / originalWidth * originalHeight)
        }

      case let (.some(width), .some(height)):
        // intrinsic size of image fits just fine
        if originalWidth <= width, originalHeight <= height {
          size = CGSize(width: originalWidth, height: originalHeight)
        }

        // shrink image proportionally to fit inside the box
        let xRatio = width / originalWidth
        let yRatio = height / originalHeight
        // use small ratio to fit the image in
        if xRatio < yRatio {
          size = CGSize(width: width, height: originalHeight * xRatio)
        } else {
          size = CGSize(width: originalWidth * yRatio, height: height)
        }
      }

      return CGSize(width: max(size.width, 200), height: min(size.height, 450))
    }
  }
}
