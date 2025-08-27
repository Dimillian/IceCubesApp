import DesignSystem
import Env
import Models
import SwiftUI

struct FamiliarFollowersView: View {
  @Environment(RouterPath.self) private var routerPath
  
  let familiarFollowers: [Account]
  
  var body: some View {
    if !familiarFollowers.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Text("account.detail.familiar-followers")
          .font(.scaledHeadline)
          .padding(.leading, .layoutPadding)
          .accessibilityAddTraits(.isHeader)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 0) {
            ForEach(familiarFollowers) { account in
              Button {
                routerPath.navigate(to: .accountDetailWithAccount(account: account))
              } label: {
                AvatarView(account.avatar, config: .badge)
                  .padding(.leading, -4)
                  .accessibilityLabel(account.safeDisplayName)
              }
              .accessibilityAddTraits(.isImage)
              .buttonStyle(.plain)
            }
          }
          .padding(.leading, .layoutPadding + 4)
        }
      }
      .padding(.top, 2)
      .padding(.bottom, 12)
    }
  }
}