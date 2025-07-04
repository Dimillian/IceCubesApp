import Account
import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

struct SearchResultsView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath
  
  let results: SearchResults
  let searchScope: SearchScope
  let onNextPage: (Search.EntityType) async -> Void
  
  var body: some View {
    Group {
      if !results.accounts.isEmpty, searchScope == .all || searchScope == .people {
        Section("explore.section.users") {
          ForEach(results.accounts) { account in
            if let relationship = results.relationships.first(where: { $0.id == account.id }) {
              AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
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
          if searchScope == .people {
            NextPageView {
              await onNextPage(.accounts)
            }
            .padding(.horizontal, .layoutPadding)
            #if !os(visionOS)
              .listRowBackground(theme.primaryBackgroundColor)
            #endif
          }
        }
      }
      
      if !results.hashtags.isEmpty,
        searchScope == .all || searchScope == .hashtags
      {
        Section("explore.section.tags") {
          ForEach(results.hashtags) { tag in
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
          if searchScope == .hashtags {
            NextPageView {
              await onNextPage(.hashtags)
            }
            .padding(.horizontal, .layoutPadding)
            #if !os(visionOS)
              .listRowBackground(theme.primaryBackgroundColor)
            #endif
          }
        }
      }
      
      if !results.statuses.isEmpty, searchScope == .all || searchScope == .posts {
        Section("explore.section.posts") {
          ForEach(results.statuses) { status in
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
          if searchScope == .posts {
            NextPageView {
              await onNextPage(.statuses)
            }
            .padding(.horizontal, .layoutPadding)
            #if !os(visionOS)
              .listRowBackground(theme.primaryBackgroundColor)
            #endif
          }
        }
      }
    }
  }
}
