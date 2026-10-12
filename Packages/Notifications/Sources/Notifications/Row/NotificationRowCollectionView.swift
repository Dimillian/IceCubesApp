import DesignSystem
import Env
import Models
import SwiftUI

/// Content shown for `added_to_collection` and `collection_update` notifications: a pill for the
/// collection that was the object of the notification, matching the one on account profiles.
@MainActor
struct NotificationRowCollectionView: View {
  let collection: AccountCollection
  let routerPath: RouterPath

  var body: some View {
    HStack {
      Button {
        routerPath.navigate(to: .collectionDetail(collection: collection))
      } label: {
        VStack(alignment: .leading, spacing: 0) {
          Text(collection.name)
            .font(.scaledCallout)
            .lineLimit(1)
            .truncationMode(.tail)
          Text("account.detail.collections-n-accounts \(collection.itemCount)")
            .font(.caption2)
        }
      }
      .buttonStyle(.bordered)
      .frame(maxWidth: 180)
      Spacer()
    }
  }
}
