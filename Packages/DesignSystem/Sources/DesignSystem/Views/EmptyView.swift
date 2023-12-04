import SwiftUI

public struct EmptyView: View {
  public let iconName: String
  public let title: LocalizedStringKey
  public let message: LocalizedStringKey

  public init(iconName: String, title: LocalizedStringKey, message: LocalizedStringKey) {
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
        .font(.scaledTitle)
        .padding(.top, 16)
      Text(message)
        .font(.scaledSubheadline)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 100)
    .padding(.layoutPadding)
    .fixedSize(horizontal: false, vertical: true)
  }
}
