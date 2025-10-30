import DesignSystem
import Env
import Models
import NukeUI
import SwiftUI
import DesignSystem

struct AccountHeaderImageView: View {
  enum Constants {
    static let headerHeight: CGFloat = 200
  }
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.redactionReasons) private var reasons
  @Environment(Theme.self) private var theme
  @Environment(QuickLook.self) private var quickLook
  
  let account: Account
  let relationship: Relationship?
  
  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Rectangle()
        .frame(height: Constants.headerHeight)
        .overlay {
          headerImageContent
        }
      
      if relationship?.followedBy == true {
        followsYouBadge
      }
    }
  }
  
  private var headerImageContent: some View {
    ZStack(alignment: .bottomTrailing) {
      if reasons.contains(.placeholder) {
        Rectangle()
          .foregroundColor(theme.secondaryBackgroundColor)
          .frame(height: Constants.headerHeight)
          .accessibilityHidden(true)
      } else {
        LazyImage(url: account.header) { state in
            if let container = state.imageContainer {
                if theme.avatarAnimated && container.type == .gif, let data = container.data {
                    GifView(data:data)
                        .aspectRatio(contentMode: .fill)
                        .overlay(account.haveHeader ? .black.opacity(0.50) : .clear)
                        .frame(height: Constants.headerHeight)
                        .clipped()
                } else {
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(account.haveHeader ? .black.opacity(0.50) : .clear)
                            .frame(height: Constants.headerHeight)
                            .clipped()
                    } else {
                        theme.secondaryBackgroundColor
                            .frame(height: Constants.headerHeight)
                    }
                }
            }
        }
        .frame(height: Constants.headerHeight)
      }
    }
    #if !os(visionOS)
      .background(theme.secondaryBackgroundColor)
    #endif
    .frame(height: Constants.headerHeight)
    .onTapGesture {
      guard account.haveHeader else { return }
      let attachement = MediaAttachment.imageWith(url: account.header)
      #if targetEnvironment(macCatalyst) || os(visionOS)
        openWindow(
          value: WindowDestinationMedia.mediaViewer(
            attachments: [attachement],
            selectedAttachment: attachement
          ))
      #else
        quickLook.prepareFor(selectedMediaAttachment: attachement, mediaAttachments: [attachement])
      #endif
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits([.isImage, .isButton])
    .accessibilityLabel("accessibility.tabs.profile.header-image.label")
    .accessibilityHint("accessibility.tabs.profile.header-image.hint")
    .accessibilityHidden(account.haveHeader == false)
  }
  
  @ViewBuilder
  private var followsYouBadge: some View {
    if #available(iOS 26.0, *) {
      Text("account.relation.follows-you")
        .font(.scaledFootnote)
        .fontWeight(.semibold)
        .padding(8)
        .glassEffect()
        .cornerRadius(4)
        .padding(8)
    } else {
      Text("account.relation.follows-you")
        .font(.scaledFootnote)
        .fontWeight(.semibold)
        .padding(4)
        .background(.ultraThinMaterial)
        .cornerRadius(4)
        .padding(8)
    }
  }
}
