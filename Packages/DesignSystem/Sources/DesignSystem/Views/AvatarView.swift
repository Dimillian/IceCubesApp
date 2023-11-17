import Nuke
import NukeUI
import Shimmer
import SwiftUI

@MainActor
public struct AvatarView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(Theme.self) private var theme

  public enum Size {
    case account, status, embed, badge, list, boost

    public var size: CGSize {
      switch self {
      case .account:
        return .init(width: 80, height: 80)
      case .status:
        if ProcessInfo.processInfo.isMacCatalystApp {
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
        size.width / 2
      default:
        4
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
        LazyImage(request: url.map { makeImageRequest(for: $0) }) { state in
          if let image = state.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            AvatarPlaceholderView(size: size)
          }
        }
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
      AnyShape(Circle())
    case .rounded:
      AnyShape(RoundedRectangle(cornerRadius: size.cornerRadius))
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
