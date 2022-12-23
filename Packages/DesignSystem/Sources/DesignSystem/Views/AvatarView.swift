import SwiftUI
import Shimmer

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
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          if size == .badge {
            Circle()
              .fill(.gray)
              .frame(width: size.size.width, height: size.size.height)
              .shimmering()
          } else {
            RoundedRectangle(cornerRadius: size.cornerRadius)
              .fill(.gray)
              .frame(width: size.size.width, height: size.size.height)
              .shimmering()
          }
        case let .success(image):
          image.resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(size.cornerRadius)
            .frame(maxWidth: size.size.width, maxHeight: size.size.height)
        case .failure:
          EmptyView()
        @unknown default:
          EmptyView()
        }
      }
    }
  }
}
