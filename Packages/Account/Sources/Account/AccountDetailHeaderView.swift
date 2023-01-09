import SwiftUI
import Models
import DesignSystem
import Env
import Shimmer
import NukeUI

struct AccountDetailHeaderView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routeurPath: RouterPath
  @Environment(\.redactionReasons) private var reasons
  
  let isCurrentUser: Bool
  let account: Account
  let relationship: Relationshionship?
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
    GeometryReader { proxy in
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
        
        if relationship?.followedBy == true {
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
        NavigationLink(value: RouteurDestinations.following(id: account.id)) {
          makeCustomInfoLabel(title: "Following", count: account.followingCount)
        }
        NavigationLink(value: RouteurDestinations.followers(id: account.id)) {
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
          account.displayNameWithEmojis
              .font(.headline)
          Text("@\(account.acct)")
              .font(.callout)
              .foregroundColor(.gray)
        }
        Spacer()
        if let relationship = relationship, !isCurrentUser {
          FollowButton(viewModel: .init(accountId: account.id,
                                        relationship: relationship))
        }
      }
      Text(account.note.asSafeAttributedString)
        .font(.body)
        .padding(.top, 8)
        .environment(\.openURL, OpenURLAction { url in
          routeurPath.handle(url: url)
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
    AccountDetailHeaderView(isCurrentUser: false,
                            account: .placeholder(),
                            relationship: .placeholder(),
                            scrollViewProxy: nil,
                            scrollOffset: .constant(0))
  }
}
