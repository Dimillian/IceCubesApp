import SwiftUI

/// Add to any `ScrollView` or `List` to enable scroll-to behaviour (e.g. useful for scroll-to-top).
///
/// This view is configured such that `.onAppear` and `.onDisappear` are called while remaining invisible to users on-screen.
public struct ScrollToView: View {
  public enum Constants {
    public static let scrollToTop = "top"
  }

  public init() {}

  public var body: some View {
    HStack { EmptyView() }
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .accessibilityHidden(true)
      .id(Constants.scrollToTop)
  }
}
