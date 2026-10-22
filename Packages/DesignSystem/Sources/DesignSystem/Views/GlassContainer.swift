import SwiftUI

/// `GlassEffectContainer` on iOS 26+, plain content on visionOS where Liquid Glass is unavailable.
@available(iOS 26.0, *)
public struct GlassContainer<Content: View>: View {
  private let spacing: CGFloat?
  private let content: Content

  public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  public var body: some View {
    #if os(visionOS)
      content
    #else
      GlassEffectContainer(spacing: spacing) {
        content
      }
    #endif
  }
}
