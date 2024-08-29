import SwiftUI

public struct ErrorView: View {
  public let title: LocalizedStringKey
  public let message: LocalizedStringKey
  public let buttonTitle: LocalizedStringKey
  public let onButtonPress: () async -> Void

  public init(title: LocalizedStringKey, message: LocalizedStringKey, buttonTitle: LocalizedStringKey, onButtonPress: @escaping (() async -> Void)) {
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.onButtonPress = onButtonPress
  }

  public var body: some View {
    HStack {
      Spacer()
      VStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxHeight: 50)
        Text(title)
          .font(.scaledTitle)
          .padding(.top, 16)
        Text(message)
          .font(.scaledSubheadline)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
        Button {
          Task {
            await onButtonPress()
          }
        } label: {
          Text(buttonTitle)
        }
        .buttonStyle(.bordered)
        .padding(.top, 16)
      }
      .padding(.top, 100)
      .padding(.layoutPadding)
      Spacer()
    }
  }
}

#Preview {
  ErrorView(title: "Error",
            message: "Error loading. Please try again",
            buttonTitle: "Retry") {}
}
