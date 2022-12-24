import SwiftUI
import Models
import DesignSystem
import Env

struct AccountDetailHeaderView: View {
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routeurPath: RouterPath
  @Environment(\.redactionReasons) private var reasons
  
  let isCurrentUser: Bool
  let account: Account
  let relationship: Relationshionship?
  
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
        AsyncImage(
          url: account.header,
          content: { image in
            image.resizable()
              .aspectRatio(contentMode: .fill)
              .frame(height: bannerHeight)
              .frame(width: proxy.frame(in: .local).width)
              .clipped()
          },
          placeholder: {
            Color.gray
              .frame(height: bannerHeight)
          }
        )
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
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(.white, lineWidth: 1)
        )
      .onTapGesture {
        Task {
          await quickLook.prepareFor(urls: [account.avatar], selectedURL: account.avatar)
        }
      }
      Spacer()
      Group {
        makeCustomInfoLabel(title: "Posts", count: account.statusesCount)
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
    .padding(.horizontal, DS.Constants.layoutPadding)
    .offset(y: -40)
  }
  
  private func makeCustomInfoLabel(title: String, count: Int) -> some View {
    VStack {
      Text("\(count)")
        .font(.headline)
        .foregroundColor(.brand)
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
                            scrollOffset: .constant(0))
  }
}
