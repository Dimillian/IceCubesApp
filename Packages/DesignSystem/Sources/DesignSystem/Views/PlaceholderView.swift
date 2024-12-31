import SwiftUI

public struct PlaceholderView: View {
  public let iconName: String
  public let title: LocalizedStringKey
  public let message: LocalizedStringKey

  public init(iconName: String, title: LocalizedStringKey, message: LocalizedStringKey) {
    self.iconName = iconName
    self.title = title
    self.message = message
  }

  public var body: some View {
    ContentUnavailableView(
      title,
      systemImage: iconName,
      description: Text(message))
  }
}

#Preview {
  PlaceholderView(
    iconName: "square.and.arrow.up.trianglebadge.exclamationmark",
    title: "Nothing to see",
    message: "This is a preview. Please try again.")
}
