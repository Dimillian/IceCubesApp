import SwiftUI

public struct AvatarView: View {
  public enum Size {
    case profile, badge
    
    var size: CGSize {
      switch self {
      case .profile:
        return .init(width: 40, height: 40)
      case .badge:
        return .init(width: 28, height: 28)
      }
    }
  }
  
  @Environment(\.redactionReasons) private var reasons
  public let url: URL
  public let size: Size
  
  public init(url: URL, size: Size = .profile) {
    self.url = url
    self.size = size
  }
  
  public var body: some View {
    if reasons == .placeholder {
      RoundedRectangle(cornerRadius: size == .profile ? 4 : size.size.width / 2)
        .fill(.gray)
        .frame(maxWidth: size.size.width, maxHeight: size.size.height)
    } else {
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          if size == .badge {
            Circle()
              .fill(.gray)
              .frame(maxWidth: size.size.width, maxHeight: size.size.height)
          } else {
            ProgressView()
              .frame(maxWidth: size.size.width, maxHeight: size.size.height)
          }
        case let .success(image):
          image.resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(size == .profile ? 4 : size.size.width / 2)
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
