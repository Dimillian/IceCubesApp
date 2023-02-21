import NukeUI
import Nuke
import Shimmer
import SwiftUI

public struct AvatarView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
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
        if isInCaptureMode, let image = Nuke.ImagePipeline.shared.cache.cachedImage(for: .init(url: url))?.image {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.size.width, height: size.size.height)
        } else {
          LazyImage(url: url) { state in
            if let image = state.image {
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            } else {
              placeholderView
            }
          }
          .animation(nil)
          .frame(width: size.size.width, height: size.size.height)
        }
      }
    }
    .clipShape(clipShape)
    .overlay(
      clipShape.stroke(Color.primary.opacity(0.25), lineWidth: 1)
    )
  }

  private var clipShape: some Shape {
    switch theme.avatarShape {
    case .circle:
      return AnyShape(Circle())
    case .rounded:
      return AnyShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
  }

  @ViewBuilder
  private var placeholderView: some View {
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
