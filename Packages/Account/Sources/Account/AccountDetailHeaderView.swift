import DesignSystem
import EmojiText
import Env
import Models
import NukeUI
import Shimmer
import SwiftUI

struct AccountDetailHeaderView: View {
  enum Constants {
    static let headerHeight: CGFloat = 200
  }

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var currentAccount: CurrentAccount
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isSupporter) private var isSupporter: Bool

  @ObservedObject var viewModel: AccountDetailViewModel
  let account: Account
  let scrollViewProxy: ScrollViewProxy?

  var body: some View {
    VStack(alignment: .leading) {
      ZStack(alignment: .bottomTrailing) {
        Rectangle()
          .frame(height: Constants.headerHeight)
          .overlay {
            headerImageView
          }
        if viewModel.relationship?.followedBy == true {
          Text("account.relation.follows-you")
            .font(.scaledFootnote)
            .fontWeight(.semibold)
            .padding(4)
            .background(.ultraThinMaterial)
            .cornerRadius(4)
            .padding(8)
        }
      }
      accountInfoView
    }
  }

  private var headerImageView: some View {
    ZStack(alignment: .bottomTrailing) {
      if reasons.contains(.placeholder) {
        Rectangle()
          .foregroundColor(theme.secondaryBackgroundColor)
          .frame(height: Constants.headerHeight)
      } else {
        LazyImage(url: account.header) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .overlay(account.haveHeader ? .black.opacity(0.50) : .clear)
              .frame(height: Constants.headerHeight)
              .clipped()
          } else if state.isLoading {
            theme.secondaryBackgroundColor
              .frame(height: Constants.headerHeight)
              .shimmering()
          } else {
            theme.secondaryBackgroundColor
              .frame(height: Constants.headerHeight)
          }
        }
        .frame(height: Constants.headerHeight)
      }
    }
    .background(theme.secondaryBackgroundColor)
    .frame(height: Constants.headerHeight)
    .contentShape(Rectangle())
    .onTapGesture {
      guard account.haveHeader else {
        return
      }
      Task {
        await quickLook.prepareFor(urls: [account.header], selectedURL: account.header)
      }
    }
  }

  private var accountAvatarView: some View {
    HStack {
      ZStack(alignment: .topTrailing) {
        AvatarView(url: account.avatar, size: .account)
          .onTapGesture {
            guard account.haveAvatar else {
              return
            }
            Task {
              await quickLook.prepareFor(urls: [account.avatar], selectedURL: account.avatar)
            }
          }
        if viewModel.isCurrentUser, isSupporter {
          Image(systemName: "checkmark.seal.fill")
            .resizable()
            .frame(width: 25, height: 25)
            .foregroundColor(theme.tintColor)
            .offset(x: theme.avatarShape == .circle ? 0 : 10,
                    y: theme.avatarShape == .circle ? 0 : -10)
        }
      }
      Spacer()
      Group {
        Button {
          withAnimation {
            scrollViewProxy?.scrollTo("status", anchor: .top)
          }
        } label: {
          makeCustomInfoLabel(title: "account.posts", count: account.statusesCount)
        }
        .buttonStyle(.borderless)

        Button {
          routerPath.navigate(to: .following(id: account.id))
        } label: {
          makeCustomInfoLabel(title: "account.following", count: account.followingCount)
        }
        .buttonStyle(.borderless)

        Button {
          routerPath.navigate(to: .followers(id: account.id))
        } label: {
          makeCustomInfoLabel(
            title: "account.followers",
            count: account.followersCount,
            needsBadge: currentAccount.account?.id == account.id && !currentAccount.followRequests.isEmpty
          )
        }
        .buttonStyle(.borderless)

      }.offset(y: 20)
    }
  }

  private var accountInfoView: some View {
    Group {
      accountAvatarView
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .center, spacing: 2) {
            EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
              .font(.scaledHeadline)
              .foregroundColor(theme.labelColor)
              .emojiSize(Font.scaledHeadlineFont.emojiSize)
              .emojiBaselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
            if account.bot {
              Text(Image(systemName: "poweroutlet.type.b.fill"))
                .font(.footnote)
            }
            if account.locked {
              Text(Image(systemName: "lock.fill"))
                .font(.footnote)
            }
            if viewModel.relationship?.blocking == true {
              Text(Image(systemName: "person.crop.circle.badge.xmark.fill"))
                .font(.footnote)
            }
            if viewModel.relationship?.muting == true {
              Text(Image(systemName: "speaker.slash.fill"))
                .font(.footnote)
            }
          }
          Text("@\(account.acct)")
            .font(.scaledCallout)
            .foregroundColor(.gray)
            .textSelection(.enabled)
          joinedAtView
        }
        Spacer()
        if let relationship = viewModel.relationship, !viewModel.isCurrentUser {
          HStack {
            FollowButton(viewModel: .init(accountId: account.id,
                                          relationship: relationship,
                                          shouldDisplayNotify: true,
                                          relationshipUpdated: { relationship in
                                            viewModel.relationship = relationship
                                          }))
          }
        }
      }

      if let note = viewModel.relationship?.note, !note.isEmpty,
         !viewModel.isCurrentUser
      {
        makeNoteView(note)
      }

      EmojiTextApp(account.note, emojis: account.emojis)
        .font(.scaledBody)
        .foregroundColor(theme.labelColor)
        .emojiSize(Font.scaledBodyFont.emojiSize)
        .emojiBaselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
        .padding(.top, 8)
        .textSelection(.enabled)
        .environment(\.openURL, OpenURLAction { url in
          routerPath.handle(url: url)
        })

      fieldsView
    }
    .padding(.horizontal, .layoutPadding)
    .offset(y: -40)
  }

  private func makeCustomInfoLabel(title: LocalizedStringKey, count: Int, needsBadge: Bool = false) -> some View {
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
        .foregroundColor(.gray)
    }
  }

  @ViewBuilder
  private var joinedAtView: some View {
    if let joinedAt = viewModel.account?.createdAt.asDate {
      HStack(spacing: 4) {
        Image(systemName: "calendar")
        Text("account.joined")
        Text(joinedAt, style: .date)
      }
      .foregroundColor(.gray)
      .font(.footnote)
      .padding(.top, 6)
    }
  }

  @ViewBuilder
  private func makeNoteView(_ note: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("account.relation.note.label")
        .foregroundColor(.gray)
      Text(note)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(.gray.opacity(0.35), lineWidth: 1)
        )
    }
  }

  @ViewBuilder
  private var fieldsView: some View {
    if !viewModel.fields.isEmpty {
      VStack(alignment: .leading) {
        ForEach(viewModel.fields) { field in
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(field.name)
                .font(.scaledHeadline)
              HStack {
                if field.verifiedAt != nil {
                  Image(systemName: "checkmark.seal")
                    .foregroundColor(Color.green.opacity(0.80))
                }
                EmojiTextApp(field.value, emojis: viewModel.account?.emojis ?? [])
                  .emojiSize(Font.scaledBodyFont.emojiSize)
                  .emojiBaselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
                  .foregroundColor(theme.tintColor)
                  .environment(\.openURL, OpenURLAction { url in
                    routerPath.handle(url: url)
                  })
              }
              .font(.scaledBody)
              if viewModel.fields.last != field {
                Divider()
                  .padding(.vertical, 4)
              }
            }
            Spacer()
          }
        }
      }
      .padding(8)
      .background(theme.secondaryBackgroundColor)
      .cornerRadius(4)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(.gray.opacity(0.35), lineWidth: 1)
      )
    }
  }
}

struct AccountDetailHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailHeaderView(viewModel: .init(account: .placeholder()),
                            account: .placeholder(),
                            scrollViewProxy: nil)
  }
}
