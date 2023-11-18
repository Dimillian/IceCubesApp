import Nuke
import NukeUI
import Shimmer
import SwiftUI

@MainActor
public struct AvatarView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(Theme.self) private var theme

  public let url: URL?
  public let config: FrameConfig

  public var body: some View {
    if reasons == .placeholder { placeholder } else { avatarImage }
  }

  private var avatarImage: some View {
    LazyImage(request: url.map {
      ImageRequest(url: $0, processors: [.resize(size: config.size)])
    }) { state in
      if let image = state.image {
        image.resizable().scaledToFill()
      } else {
        RoundedRectangle(cornerRadius: cornerRadius).fill(.gray)
      }
    }
    .frame(width: config.width, height: config.height)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(.primary.opacity(0.25), lineWidth: 1)
    )
  }

  private var placeholder: some View {
    RoundedRectangle(cornerRadius: cornerRadius).fill(.gray)
      .frame(width: config.width, height: config.height)
  }

  private var cornerRadius: CGFloat {
    if config == .badge || theme.avatarShape == .circle {
      return config.width / 2
    } else {
      return config.cornerRadius
    }
  }

  public init(url: URL?, config: FrameConfig = FrameConfig.status) {
    self.url = url
    self.config = config
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
    VStack {
      AvatarView(url: Self.url, config: .account)
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

  private static let url = URL(string: "https://static.independent.co.uk/s3fs-public/thumbnails/image/2014/03/25/12/eiffel.jpg")!
}
