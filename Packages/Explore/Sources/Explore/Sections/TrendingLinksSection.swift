import DesignSystem
import Env
import Models
import StatusKit
import SwiftUI

struct TrendingLinksSection: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  
  let trendingLinks: [Card]
  
  var body: some View {
    Section("explore.section.trending.links") {
      ForEach(
        trendingLinks
          .prefix(upTo: trendingLinks.count > 3 ? 3 : trendingLinks.count)
      ) { card in
        StatusRowCardView(card: card)
          .environment(\.isCompact, true)
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
      
      NavigationLink(value: RouterDestination.trendingLinks(cards: trendingLinks)) {
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