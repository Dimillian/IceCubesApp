import SwiftUI
import Shimmer
import NukeUI
import Nuke

public struct AvatarView: View {
  public enum Size {
    case account, status, badge
    
    var size: CGSize {
      switch self {
      case .account:
        return .init(width: 80, height: 80)
      case .status:
        return .init(width: 40, height: 40)
      case .badge:
        return .init(width: 28, height: 28)
      }
    }
    
    var cornerRadius: CGFloat {
      switch self {
      case .badge:
        return size.width / 2
      default:
        return 4
      }
    }
  }
  
  @Environment(\.redactionReasons) private var reasons
  public let url: URL
  public let size: Size
  
  public init(url: URL, size: Size = .status) {
    self.url = url
    self.size = size
  }
  
  public var body: some View {
    if reasons == .placeholder {
      RoundedRectangle(cornerRadius: size.cornerRadius)
        .fill(.gray)
        .frame(maxWidth: size.size.width, maxHeight: size.size.height)
    } else {
      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizingMode(.aspectFit)
        } else if state.isLoading {
          placeholderView
            .shimmering()
        } else {
          placeholderView
        }
      }
      .processors([ImageProcessors.Resize(size: size.size),
                   ImageProcessors.RoundedCorners(radius: size.cornerRadius)])
      .frame(width: size.size.width, height: size.size.height)
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
