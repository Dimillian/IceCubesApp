import DesignSystem
import Env
import Models
import SwiftUI

struct FeaturedTagsView: View {
  @Environment(RouterPath.self) private var routerPath
  
  let featuredTags: [FeaturedTag]
  let accountId: String
  
  var body: some View {
    if !featuredTags.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          ForEach(featuredTags) { tag in
            Button {
              routerPath.navigate(to: .hashTag(tag: tag.name, account: accountId))
            } label: {
              VStack(alignment: .leading, spacing: 0) {
                Text("#\(tag.name)")
                  .font(.scaledCallout)
                Text("account.detail.featured-tags-n-posts \(tag.statusesCountInt)")
                  .font(.caption2)
              }
            }.buttonStyle(.bordered)
          }
        }
        .padding(.leading, .layoutPadding)
      }
    }
  }
}