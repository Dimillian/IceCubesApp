import SwiftUI

#if !targetEnvironment(macCatalyst)
  import WishKit

  struct WishlistView: View {
    var body: some View {
      WishKit.FeedbackListView()
    }
  }
#endif
