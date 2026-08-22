import DesignSystem
import Env
import Models
import SwiftUI

struct AccountCollectionsView: View {
  @Environment(RouterPath.self) private var routerPath

  let collections: [AccountCollection]

  var body: some View {
    if !collections.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          ForEach(collections) { collection in
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
          }
        }
        .padding(.leading, .layoutPadding)
      }
      .padding(.top, 8)
    }
  }
}
