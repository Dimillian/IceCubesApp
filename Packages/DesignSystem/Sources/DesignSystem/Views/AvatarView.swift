import SwiftUI

public struct AvatarView: View {
  @Environment(\.redactionReasons) private var reasons
  public let url: URL
  
  public init(url: URL) {
    self.url = url
  }
  
  public var body: some View {
    if reasons == .placeholder {
      RoundedRectangle(cornerRadius: 4)
        .fill(.gray)
        .frame(maxWidth: 40, maxHeight: 40)
    } else {
      AsyncImage(
        url: url,
        content: { image in
          image.resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(4)
            .frame(maxWidth: 40, maxHeight: 40)
        },
        placeholder: {
          ProgressView()
            .frame(maxWidth: 40, maxHeight: 40)
        }
      )
    }
  }
}
