import Nuke
import NukeUI
import Shimmer
import SwiftUI

public struct AvatarView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var theme: Theme

  public enum Size {
    case account, status, embed, badge, list, boost

    public var size: CGSize {
      switch self {
      case .account:
        return .init(width: 80, height: 80)
      case .status:
        if ProcessInfo.processInfo.isiOSAppOnMac {
          return .init(width: 48, height: 48)
        }
        return .init(width: 40, height: 40)
      case .embed:
        return .init(width: 34, height: 34)
      case .badge:
        return .init(width: 28, height: 28)
      case .list:
        return .init(width: 20, height: 20)
      case .boost:
        return .init(width: 12, height: 12)
      }
    }

    var cornerRadius: CGFloat {
      switch self {
      case .badge, .boost, .list:
        return size.width / 2
      default:
        return 4
      }
    }
  }

  public let url: URL?
  public let size: Size

  public init(url: URL?, size: Size = .status) {
    self.url = url
    self.size = size
  }

  public var body: some View {
    Group {
      if reasons == .placeholder {
        RoundedRectangle(cornerRadius: size.cornerRadius)
          .fill(.gray)
          .frame(width: size.size.width, height: size.size.height)
      } else {
        LazyImage(request: url.map(makeImageRequest)) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
          } else {
            AvatarPlaceholderView(size: size)
          }
        }
        .animation(nil)
        .frame(width: size.size.width, height: size.size.height)
      }
    }
    .clipShape(clipShape)
    .overlay(
      clipShape.stroke(Color.primary.opacity(0.25), lineWidth: 1)
    )
  }

  private func makeImageRequest(for url: URL) -> ImageRequest {
    ImageRequest(url: url, processors: [.resize(size: size.size)])
  }

  private var clipShape: some Shape {
    switch theme.avatarShape {
    case .circle:
      return AnyShape(Circle())
    case .rounded:
      return AnyShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
  }
}

private struct AvatarPlaceholderView: View {
  let size: AvatarView.Size

  var body: some View {
    if size == .badge {
      Circle()
        .fill(.gray)
        .frame(width: size.size.width, height: size.size.height)
    } else {
      RoundedRectangle(cornerRadius: size.cornerRadius)
        .fill(.gray)
        .frame(width: size.size.width, height: size.size.height)
    }
  }
}
