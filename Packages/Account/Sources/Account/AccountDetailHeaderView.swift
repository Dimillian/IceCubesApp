import DesignSystem
import EmojiText
import Env
import Models
import NukeUI
import Shimmer
import SwiftUI

struct AccountDetailHeaderView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routerPath: RouterPath
  @Environment(\.redactionReasons) private var reasons

  @ObservedObject var viewModel: AccountDetailViewModel
  let account: Account
  let scrollViewProxy: ScrollViewProxy?

  @Binding var scrollOffset: CGFloat

  private var bannerHeight: CGFloat {
    200 + (scrollOffset > 0 ? scrollOffset * 2 : 0)
  }

  var body: some View {
    VStack(alignment: .leading) {
      headerImageView
      accountInfoView
    }
  }

  private var headerImageView: some View {
    GeometryReader { _ in
      ZStack(alignment: .bottomTrailing) {
        if reasons.contains(.placeholder) {
          Rectangle()
            .foregroundColor(.gray)
            .frame(height: bannerHeight)
        } else {
          LazyImage(url: account.header) { state in
            if let image = state.image {
              image
                .resizingMode(.aspectFill)
                .overlay(.black.opacity(0.50))
            } else if state.isLoading {
              Color.gray
                .frame(height: bannerHeight)
                .shimmering()
            } else {
              Color.gray
                .frame(height: bannerHeight)
            }
          }
          .frame(height: bannerHeight)
        }

        if viewModel.relationship?.followedBy == true {
          Text("Follows You")
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(4)
            .background(.ultraThinMaterial)
            .cornerRadius(4)
            .padding(8)
        }
      }
      .background(Color.gray)
    }
    .frame(height: bannerHeight)
    .offset(y: scrollOffset > 0 ? -scrollOffset : 0)
    .contentShape(Rectangle())
    .onTapGesture {
      Task {
        await quickLook.prepareFor(urls: [account.header], selectedURL: account.header)
      }
    }
  }

  private var accountAvatarView: some View {
    HStack {
      AvatarView(url: account.avatar, size: .account)
        .onTapGesture {
          Task {
            await quickLook.prepareFor(urls: [account.avatar], selectedURL: account.avatar)
          }
        }
      Spacer()
      Group {
        Button {
          withAnimation {
            scrollViewProxy?.scrollTo("status", anchor: .top)
          }
        } label: {
          makeCustomInfoLabel(title: "Posts", count: account.statusesCount)
        }
        NavigationLink(value: RouterDestinations.following(id: account.id)) {
          makeCustomInfoLabel(title: "Following", count: account.followingCount)
        }
        NavigationLink(value: RouterDestinations.followers(id: account.id)) {
          makeCustomInfoLabel(title: "Followers", count: account.followersCount)
        }
      }.offset(y: 20)
    }
  }

  private var accountInfoView: some View {
    Group {
      accountAvatarView
      HStack {
        VStack(alignment: .leading, spacing: 0) {
          EmojiTextApp(account.safeDisplayName.asMarkdown, emojis: account.emojis)
            .font(.headline)
          Text("@\(account.acct)")
            .font(.callout)
            .foregroundColor(.gray)
        }
        Spacer()
        if let relationship = viewModel.relationship, !viewModel.isCurrentUser {
          HStack {
            FollowButton(viewModel: .init(accountId: account.id,
                                          relationship: relationship,
                                          shouldDisplayNotify: true))
          }
        }
      }
      EmojiTextApp(account.note.asMarkdown, emojis: account.emojis)
        .font(.body)
        .padding(.top, 8)
        .environment(\.openURL, OpenURLAction { url in
          routerPath.handle(url: url)
        })
    }
    .padding(.horizontal, .layoutPadding)
    .offset(y: -40)
  }

  private func makeCustomInfoLabel(title: String, count: Int) -> some View {
    VStack {
      Text("\(count)")
        .font(.headline)
        .foregroundColor(theme.tintColor)
      Text(title)
        .font(.footnote)
        .foregroundColor(.gray)
    }
  }
}

struct AccountDetailHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailHeaderView(viewModel: .init(account: .placeholder()),
                            account: .placeholder(),
                            scrollViewProxy: nil,
                            scrollOffset: .constant(0))
  }
}
