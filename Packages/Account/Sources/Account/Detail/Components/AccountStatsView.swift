import DesignSystem
import Env
import Models
import SwiftUI

struct AccountStatsView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var currentAccount
  
  let account: Account
  let scrollViewProxy: ScrollViewProxy?
  
  var body: some View {
    Group {
      Button {
        withAnimation {
          scrollViewProxy?.scrollTo("status", anchor: .top)
        }
      } label: {
        makeCustomInfoLabel(title: "account.posts", count: account.statusesCount ?? 0)
      }
      .accessibilityHint("accessibility.tabs.profile.post-count.hint")
      .buttonStyle(.borderless)

      Button {
        routerPath.navigate(to: .following(id: account.id))
      } label: {
        makeCustomInfoLabel(title: "account.following", count: account.followingCount ?? 0)
      }
      .accessibilityHint("accessibility.tabs.profile.following-count.hint")
      .buttonStyle(.borderless)

      Button {
        routerPath.navigate(to: .followers(id: account.id))
      } label: {
        makeCustomInfoLabel(
          title: "account.followers",
          count: account.followersCount ?? 0,
          needsBadge: currentAccount.account?.id == account.id
            && !currentAccount.followRequests.isEmpty
        )
      }
      .accessibilityHint("accessibility.tabs.profile.follower-count.hint")
      .buttonStyle(.borderless)
    }
    .offset(y: 20)
  }
  
  private func makeCustomInfoLabel(title: LocalizedStringKey, count: Int, needsBadge: Bool = false)
    -> some View
  {
    VStack {
      Text(count, format: .number.notation(.compactName))
        .font(.scaledHeadline)
        .foregroundColor(theme.tintColor)
        .overlay(alignment: .trailing) {
          if needsBadge {
            Circle()
              .fill(Color.red)
              .frame(width: 9, height: 9)
              .offset(x: 12)
          }
        }
      Text(title)
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue("\(count)")
  }
}