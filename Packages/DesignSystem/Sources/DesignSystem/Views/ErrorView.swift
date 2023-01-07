import SwiftUI

public struct ErrorView: View {
  public let title: String
  public let message: String
  public let buttonTitle: String
  public let onButtonPress: (() -> Void)
  
  public init(title: String, message: String, buttonTitle: String, onButtonPress: @escaping (() -> Void)) {
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.onButtonPress = onButtonPress
  }
  
  public var body: some View {
    VStack {
      Image(systemName: "exclamationmark.triangle.fill")
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
      Button {
        onButtonPress()
      } label: {
        Text(buttonTitle)
      }
      .buttonStyle(.bordered)
      .padding(.top, 16)
    }
    .padding(.top, 100)
    .padding(.layoutPadding)
  }
}
