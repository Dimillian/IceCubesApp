import Nuke
import NukeUI
import Shimmer
import SwiftUI
import Models

@MainActor
public struct AvatarView: View {
  @Environment(Theme.self) private var theme

  @State private var showPopup = false
  @State private var autoDismiss = true
  @State private var toggleTask: Task<Void, Never> = Task {}

  public let account: Account?
  public let config: FrameConfig
  public let hasPopup: Bool

  public var body: some View {
    if let account = account {
      if hasPopup {
        AvatarImage(account: account, config: adaptiveConfig)
          .onHover { hovering in
            toggleTask.cancel()
            toggleTask = Task {
              try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
              guard !Task.isCancelled else { return }
              if !showPopup && hovering {
                showPopup = true
              }
            }
          }
          .popover(isPresented: $showPopup) {
            AccountPopupView(
              account: account,
              theme: theme,
              showPopup: $showPopup,
              autoDismiss: $autoDismiss,
              toggleTask: $toggleTask
            )
          }
      } else {
        AvatarImage(account: account, config: adaptiveConfig)
      }
    } else {
      AvatarPlaceHolder(config: adaptiveConfig)
    }
  }

  private var adaptiveConfig: FrameConfig {
    var cornerRadius: CGFloat
    if config == .badge || theme.avatarShape == .circle {
      cornerRadius = config.width / 2
    } else {
      cornerRadius = config.cornerRadius
    }
    return FrameConfig(width: config.width, height: config.height, cornerRadius: cornerRadius)
  }

  public init(account: Account?, config: FrameConfig = FrameConfig.status, hasPopup: Bool = true) {
    self.account = account
    self.config = config
    self.hasPopup = hasPopup
  }

  public struct FrameConfig: Equatable {
    public let size: CGSize
    public var width: CGFloat { size.width }
    public var height: CGFloat { size.height }
    let cornerRadius: CGFloat

    init(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 4) {
      self.size = CGSize(width: width, height: height)
      self.cornerRadius = cornerRadius
    }

    public static let account = FrameConfig(width: 80, height: 80)
    public static let status = {
      if ProcessInfo.processInfo.isMacCatalystApp {
        return FrameConfig(width: 48, height: 48)
      }
      return FrameConfig(width: 40, height: 40)
    }()
    public static let embed = FrameConfig(width: 34, height: 34)
    public static let badge = FrameConfig(width: 28, height: 28, cornerRadius: 14)
    public static let list = FrameConfig(width: 20, height: 20, cornerRadius: 10)
    public static let boost = FrameConfig(width: 12, height: 12, cornerRadius: 6)
  }
}

struct AvatarView_Previews: PreviewProvider {
  static var previews: some View {
    PreviewWrapper()
      .padding()
      .previewLayout(.sizeThatFits)
  }
}

struct PreviewWrapper: View {
  @State private var isCircleAvatar = false

  var body: some View {
    VStack(alignment: .leading) {
      AvatarView(account: Self.account, config: .status)
        .environment(Theme.shared)
      Toggle("Avatar Shape", isOn: $isCircleAvatar)
    }
    .onChange(of: isCircleAvatar) {
      Theme.shared.avatarShape = self.isCircleAvatar ? .circle : .rounded
    }
    .onAppear {
      Theme.shared.avatarShape = self.isCircleAvatar ? .circle : .rounded
    }
  }

  private static let account = Account(
    id: UUID().uuidString,
    username: "@clattner_llvm",
    displayName: "Chris Lattner",
    avatar: URL(string: "https://pbs.twimg.com/profile_images/1484209565788897285/1n6Viahb_400x400.jpg")!,
    header: URL(string: "https://pbs.twimg.com/profile_banners/2543588034/1656822255/1500x500")!,
    acct: "clattner_llvm@example.com",
    note: .init(stringValue: "Building beautiful things @Modular_AI 🔥, lifting the world of production AI/ML software into a new phase of innovation.  We’re hiring! 🚀🧠"),
    createdAt: ServerDate(),
    followersCount: 77100,
    followingCount: 167,
    statusesCount: 123,
    lastStatusAt: nil,
    fields: [],
    locked: false,
    emojis: [],
    url: URL(string: "https://nondot.org/sabre/")!,
    source: nil,
    bot: false,
    discoverable: true)
}

struct AvatarImage: View {
  @Environment(\.redactionReasons) private var reasons

  public let account: Account
  public let config: AvatarView.FrameConfig

  var body: some View {
    if reasons == .placeholder {
      AvatarPlaceHolder(config: config)
    } else {
      LazyImage(request: ImageRequest(url: account.avatar, processors: [.resize(size: config.size)])
      ) { state in
        if let image = state.image {
          image.resizable().scaledToFill()
            .frame(width: config.width, height: config.height)
            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
            .overlay(
              RoundedRectangle(cornerRadius: config.cornerRadius)
                .stroke(.primary.opacity(0.25), lineWidth: 1)
            )
        }
      }
    }
  }
}

struct AvatarPlaceHolder: View {
  let config: AvatarView.FrameConfig

  var body: some View {
    RoundedRectangle(cornerRadius: config.cornerRadius)
      .fill(.gray)
      .frame(width: config.width, height: config.height)
  }
}

struct AccountPopupView: View {
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
          AvatarImage(account: account, config: adaptiveConfig)
          Spacer()
          makeCustomInfoLabel(title: "account.following", count: account.followingCount ?? 0)
          makeCustomInfoLabel(title: "account.posts", count: account.statusesCount ?? 0)
          makeCustomInfoLabel(title: "account.followers", count: account.followersCount ?? 0)
        }
        .frame(height: adaptiveConfig.height / 2, alignment: .bottom)

        EmojiTextApp(.init(stringValue: account.safeDisplayName ), emojis: account.emojis)
          .font(.headline)
          .foregroundColor(theme.labelColor)
          .emojiSize(Font.scaledHeadlineFont.emojiSize)
          .emojiBaselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
          .accessibilityAddTraits(.isHeader)
          .help(account.safeDisplayName)

        Text("@\(account.acct)")
          .font(.callout)
          .foregroundColor(.gray)
          .textSelection(.enabled)
          .accessibilityRespondsToUserInteraction(false)
          .help("@\(account.acct)")

        HStack(spacing: 4) {
          Image(systemName: "calendar")
            .accessibilityHidden(true)
          Text("account.joined")
          Text(account.createdAt.asDate, style: .date)
        }
        .foregroundColor(.gray)
        .font(.footnote)
        .accessibilityElement(children: .combine)

        EmojiTextApp(account.note, emojis: account.emojis, lineLimit: 5)
          .font(.body)
          .emojiSize(Font.scaledFootnoteFont.emojiSize)
          .emojiBaselineOffset(Font.scaledFootnoteFont.emojiBaselineOffset)
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
        .foregroundColor(.gray)
        .alignmentGuide(.bottomAvatar, computeValue: { dimension in
          dimension[.firstTextBaseline]
        })
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue("\(count)")
  }

  private var adaptiveConfig: AvatarView.FrameConfig {
    var cornerRadius: CGFloat
    if config == .badge || theme.avatarShape == .circle {
      cornerRadius = config.width / 2
    } else {
      cornerRadius = config.cornerRadius
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
