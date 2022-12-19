import SwiftUI
import Models
import DesignSystem

struct AccountDetailHeaderView: View {
  @Environment(\.redactionReasons) private var reasons
  let account: Account
  
  var body: some View {
    VStack(alignment: .leading) {
      headerImageView
      accountInfoView
    }
  }
  
  private var headerImageView: some View {
    AsyncImage(
      url: account.header,
      content: { image in
        image.resizable()
          .aspectRatio(contentMode: .fill)
          .frame(maxHeight: 200)
          .clipped()
      },
      placeholder: {
        Color.gray
          .frame(maxHeight: 20)
      }
    )
    .frame(maxHeight: 200)
    .background(Color.gray)
  }
  
  private var accountAvatarView: some View {
    HStack {
      AsyncImage(
        url: account.avatar,
        content: { image in
          image.resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(4)
            .frame(maxWidth: 80, maxHeight: 80)
            .overlay(
              RoundedRectangle(cornerRadius: 4)
                .stroke(.white, lineWidth: 1)
            )
        },
        placeholder: {
          ProgressView()
            .frame(maxWidth: 80, maxHeight: 80)
        }
      )
      Spacer()
      Group {
        makeCustomInfoLabel(title: "Posts", count: account.statusesCount)
        makeCustomInfoLabel(title: "Following", count: account.followingCount)
        makeCustomInfoLabel(title: "Followers", count: account.followersCount)
      }.offset(y: 20)
    }
  }
  
  private var accountInfoView: some View {
    Group {
      accountAvatarView
      Text(account.displayName)
        .font(.headline)
      Text(account.acct)
        .font(.callout)
        .foregroundColor(.gray)
      Text(account.note.asSafeAttributedString)
        .font(.body)
        .padding(.top, 8)
    }
    .padding(.horizontal, DS.Constants.layoutPadding)
    .offset(y: -40)
  }
  
  private func makeCustomInfoLabel(title: String, count: Int) -> some View {
    VStack {
      Text("\(count)")
        .font(.headline)
      Text(title)
        .font(.footnote)
        .foregroundColor(.gray)
    }
  }
}

struct AccountDetailHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailHeaderView(account: .placeholder())
  }
}
