import Env
import Models
import Nuke
import NukeUI
import SwiftUI

@MainActor
struct AccountPopoverView: View {
  let account: Account
  let theme: Theme // using `@Environment(Theme.self) will crash the SwiftUI preview
  private let config: AvatarView.FrameConfig = .account

  @Binding var showPopup: Bool
  @Binding var autoDismiss: Bool
  @Binding var toggleTask: Task<Void, Never>

  var body: some View {
    VStack(alignment: .leading) {
      LazyImage(request: ImageRequest(url: account.header)
      ) { state in
        if let image = state.image {
          image.resizable().scaledToFill()
        }
      }
      .frame(width: 500, height: 150)
      .clipped()
      .background(theme.secondaryBackgroundColor)

      VStack(alignment: .leading) {
        HStack(alignment: .bottomAvatar) {
          AvatarImage(account.avatar, config: adaptiveConfig)
          Spacer()
          makeCustomInfoLabel(title: "account.following", count: account.followingCount ?? 0)
          makeCustomInfoLabel(title: "account.posts", count: account.statusesCount ?? 0)
          makeCustomInfoLabel(title: "account.followers", count: account.followersCount ?? 0)
        }
        .frame(height: adaptiveConfig.height / 2, alignment: .bottom)

        EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
          .font(.headline)
          .foregroundColor(theme.labelColor)
          .emojiText.size(Font.scaledHeadlineFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
          .accessibilityAddTraits(.isHeader)
          .help(account.safeDisplayName)

        Text("@\(account.acct)")
          .font(.callout)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .accessibilityRespondsToUserInteraction(false)
          .help("@\(account.acct)")

        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .accessibilityHidden(true)
          Text("account.joined")
          Text(account.createdAt.asDate, style: .date)
        }
        .foregroundStyle(.secondary)
        .font(.footnote)
        .accessibilityElement(children: .combine)

        EmojiTextApp(account.note, emojis: account.emojis, lineLimit: 5)
          .font(.body)
          .emojiText.size(Font.scaledFootnoteFont.emojiSize)
          .emojiText.baselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
          .padding(.top, 3)
      }
      .padding([.leading, .trailing, .bottom])
    }
    .frame(width: 500)
    .onAppear {
      toggleTask.cancel()
      toggleTask = Task {
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
        guard !Task.isCancelled else { return }
        if autoDismiss {
          showPopup = false
        }
      }
    }
    .onHover { hovering in
      toggleTask.cancel()
      toggleTask = Task {
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        guard !Task.isCancelled else { return }
        if hovering {
          autoDismiss = false
        } else {
          showPopup = false
          autoDismiss = true
        }
      }
    }
  }

  @MainActor
  private func makeCustomInfoLabel(title: LocalizedStringKey, count: Int, needsBadge: Bool = false) -> some View {
    VStack {
      Text(count, format: .number.notation(.compactName))
        .font(.scaledHeadline)
        .foregroundColor(theme.tintColor)
        .overlay(alignment: .trailing) {
          if needsBadge {
            Circle()
              .fill(Color.red)
              .frame(width: 9, height: 9)
              .offset(x: 12)
          }
        }
      Text(title)
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
        .alignmentGuide(.bottomAvatar, computeValue: { dimension in
          dimension[.firstTextBaseline]
        })
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue("\(count)")
  }

  private var adaptiveConfig: AvatarView.FrameConfig {
    let cornerRadius: CGFloat = if config == .badge || theme.avatarShape == .circle {
      config.width / 2
    } else {
      config.cornerRadius
    }
    return AvatarView.FrameConfig(width: config.width, height: config.height, cornerRadius: cornerRadius)
  }
}

private enum BottomAvatarAlignment: AlignmentID {
  static func defaultValue(in context: ViewDimensions) -> CGFloat {
    context.height
  }
}

extension VerticalAlignment {
  static let bottomAvatar = VerticalAlignment(BottomAvatarAlignment.self)
}

public struct AccountPopoverModifier: ViewModifier {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  @State private var showPopup = false
  @State private var autoDismiss = true
  @State private var toggleTask: Task<Void, Never> = Task {}

  let account: Account

  public func body(content: Content) -> some View {
    if !userPreferences.showAccountPopover {
      return AnyView(content)
    }

    return AnyView(content
      .onHover { hovering in
        if hovering {
          toggleTask.cancel()
          toggleTask = Task {
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
            guard !Task.isCancelled else { return }
            if !showPopup {
              showPopup = true
            }
          }
        } else {
          if !showPopup {
            toggleTask.cancel()
          }
        }
      }
      .hoverEffect(.lift)
      .popover(isPresented: $showPopup) {
        AccountPopoverView(
          account: account,
          theme: theme,
          showPopup: $showPopup,
          autoDismiss: $autoDismiss,
          toggleTask: $toggleTask
        )
      })
  }

  init(_ account: Account) {
    self.account = account
  }
}

public extension View {
  func accountPopover(_ account: Account) -> some View {
    modifier(AccountPopoverModifier(account))
  }
}
