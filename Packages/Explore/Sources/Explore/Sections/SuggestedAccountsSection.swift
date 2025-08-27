import Account
import DesignSystem
import Env
import Models
import SwiftUI

struct SuggestedAccountsSection: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  
  let suggestedAccounts: [Account]
  let suggestedAccountsRelationShips: [Relationship]
  
  var body: some View {
    Section("explore.section.suggested-users") {
      ForEach(
        suggestedAccounts
          .prefix(
            upTo: suggestedAccounts.count > 3 ? 3 : suggestedAccounts.count)
      ) { account in
        if let relationship = suggestedAccountsRelationShips.first(where: {
          $0.id == account.id
        }) {
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
      NavigationLink(value: RouterDestination.accountsList(accounts: suggestedAccounts)) {
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