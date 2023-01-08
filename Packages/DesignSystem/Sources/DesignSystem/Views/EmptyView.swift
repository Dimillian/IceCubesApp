import SwiftUI

public struct EmptyView: View {
  public let iconName: String
  public let title: String
  public let message: String
  
  public init(iconName: String, title: String, message: String) {
    self.iconName = iconName
    self.title = title
    self.message = message
  }
  
  public var body: some View {
    VStack {
      Image(systemName: iconName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: 50)
      Text(title)
        .font(.title)
        .padding(.top, 16)
      Text(message)
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .foregroundColor(.gray)
    }
    .padding(.top, 100)
    .padding(.layoutPadding)
    .fixedSize(horizontal: false, vertical: true)
  }
}
