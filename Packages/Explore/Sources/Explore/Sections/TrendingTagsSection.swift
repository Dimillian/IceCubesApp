import DesignSystem
import Env
import Models
import SwiftUI

struct TrendingTagsSection: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  
  let trendingTags: [Tag]
  
  var body: some View {
    Section("explore.section.trending.tags") {
      ForEach(
        trendingTags
          .prefix(upTo: trendingTags.count > 5 ? 5 : trendingTags.count)
      ) { tag in
        TagRowView(tag: tag)
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #else
            .listRowBackground(
              RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(.background).hoverEffect()
            )
            .listRowHoverEffectDisabled()
          #endif
          .padding(.vertical, 4)
      }
      NavigationLink(value: RouterDestination.tagsList(tags: trendingTags)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #else
        .listRowBackground(
          RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.background).hoverEffect()
        )
        .listRowHoverEffectDisabled()
      #endif
    }
  }
}