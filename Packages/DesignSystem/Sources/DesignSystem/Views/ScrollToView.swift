import SwiftUI

/// Add to any `ScrollView` or `List` to enable scroll-to behaviour (e.g. useful for scroll-to-top).
///
/// This view is configured such that `.onAppear` and `.onDisappear` are called while remaining invisible to users on-screen.
public struct ScrollToView: View {
    
  public init() {}
  
  public var body: some View {
    HStack { SwiftUI.EmptyView() }
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .accessibilityHidden(true)
  }
}
