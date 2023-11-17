import Nuke
import NukeUI
import Shimmer
import SwiftUI

@MainActor
public struct AvatarView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(Theme.self) private var theme

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

  public let url: URL?
  public let config: FrameConfig

  public init(url: URL?, config: FrameConfig = FrameConfig.status) {
    self.url = url
    self.config = config
  }

  public var body: some View {
    Group {
      if reasons == .placeholder {
        RoundedRectangle(cornerRadius: config.cornerRadius)
          .fill(.gray)
          .frame(width: config.width, height: config.height)
      } else {
        LazyImage(request: url.map { makeImageRequest(for: $0) }) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            AvatarPlaceholderView(config: config)
          }
        }
        .frame(width: config.width, height: config.height)
      }
    }
    .clipShape(clipShape)
    .overlay(
      clipShape.stroke(Color.primary.opacity(0.25), lineWidth: 1)
    )
  }

  private func makeImageRequest(for url: URL) -> ImageRequest {
    ImageRequest(url: url, processors: [.resize(size: config.size)])
  }

  private var clipShape: some Shape {
    switch theme.avatarShape {
    case .circle:
      AnyShape(Circle())
    case .rounded:
      AnyShape(RoundedRectangle(cornerRadius: config.cornerRadius))
    }
  }
}

private struct AvatarPlaceholderView: View {
  let config: AvatarView.FrameConfig

  var body: some View {
    if config == .badge {
      Circle()
        .fill(.gray)
        .frame(width: config.width, height: config.height)
    } else {
      RoundedRectangle(cornerRadius: config.cornerRadius)
        .fill(.gray)
        .frame(width: config.width, height: config.height)
    }
  }
}
