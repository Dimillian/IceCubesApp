import SwiftUI

public struct ImageSheetView: View {
  let url: URL
  
  public init(url: URL) {
    self.url = url
  }
  
  public var body: some View {
    AsyncImage(
      url: url,
      content: { image in
        image.resizable()
          .aspectRatio(contentMode: .fit)
      },
      placeholder: {
        ProgressView()
      }
    )
  }
}
