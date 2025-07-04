import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct TrendingPostsSection: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  
  let trendingStatuses: [Status]
  
  var body: some View {
    Section("explore.section.trending.posts") {
      ForEach(
        trendingStatuses
          .prefix(upTo: trendingStatuses.count > 3 ? 3 : trendingStatuses.count)
      ) { status in
        StatusRowExternalView(
          viewModel: .init(status: status, client: client, routerPath: routerPath)
        )
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #else
          .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background).hoverEffect()
          )
          .listRowHoverEffectDisabled()
        #endif
        .padding(.vertical, 8)
      }
      
      NavigationLink(value: RouterDestination.trendingTimeline) {
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
