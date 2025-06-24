import DesignSystem
import Env
import Models
import SwiftUI

struct AccountAvatarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.isSupporter) private var isSupporter: Bool
  @Environment(Theme.self) private var theme
  @Environment(QuickLook.self) private var quickLook
  
  let account: Account
  let isCurrentUser: Bool
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      AvatarView(account.avatar, config: .account)
        .accessibilityLabel("accessibility.tabs.profile.user-avatar.label")
      
      if isCurrentUser, isSupporter {
        supporterBadge
      }
    }
    .onTapGesture {
      guard account.haveAvatar else { return }
      let attachement = MediaAttachment.imageWith(url: account.avatar)
      #if targetEnvironment(macCatalyst) || os(visionOS)
        openWindow(
          value: WindowDestinationMedia.mediaViewer(
            attachments: [attachement],
            selectedAttachment: attachement))
      #else
        quickLook.prepareFor(
          selectedMediaAttachment: attachement, mediaAttachments: [attachement])
      #endif
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits([.isImage, .isButton])
    .accessibilityHint("accessibility.tabs.profile.user-avatar.hint")
    .accessibilityHidden(account.haveAvatar == false)
  }
  
  private var supporterBadge: some View {
    Image(systemName: "checkmark.seal.fill")
      .resizable()
      .frame(width: 25, height: 25)
      .foregroundColor(theme.tintColor)
      .offset(
        x: theme.avatarShape == .circle ? 0 : 10,
        y: theme.avatarShape == .circle ? 0 : -10
      )
      .accessibilityRemoveTraits(.isSelected)
      .accessibilityLabel("accessibility.tabs.profile.user-avatar.supporter.label")
  }
}