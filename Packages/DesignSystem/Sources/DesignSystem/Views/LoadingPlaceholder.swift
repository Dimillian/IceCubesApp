import Shimmer
import SwiftUI

public struct LoadingPlaceholder: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .shimmering()
    }
}

extension View {
    /// Applies a shimmering loading indicator effect.
    public func loading() -> some View {
        modifier(LoadingPlaceholder())
    }
}
