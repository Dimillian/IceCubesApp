import SwiftUI

private struct CardBackgroundModifier: ViewModifier {
  @Environment(Theme.self) private var theme

  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      #if os(visionOS)
        content.glassBackgroundEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
      #else
        content.glassEffect(
          .regular.tint(theme.secondaryBackgroundColor).interactive(),
          in: RoundedRectangle(cornerRadius: cornerRadius)
        )
      #endif
    } else {
      content
        .background(
          theme.secondaryBackgroundColor,
          in: RoundedRectangle(cornerRadius: cornerRadius)
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(theme.labelColor.opacity(0.15), lineWidth: 1)
        )
    }
  }
}

extension View {
  public func withCardBackground(cornerRadius: CGFloat) -> some View {
    modifier(CardBackgroundModifier(cornerRadius: cornerRadius))
  }
}
