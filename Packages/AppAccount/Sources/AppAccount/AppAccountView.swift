import DesignSystem
import EmojiText
import Env
import SwiftUI

public struct AppAccountView: View {
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var appAccounts: AppAccountsManager
  @EnvironmentObject private var preferences: UserPreferences
  
  @StateObject var viewModel: AppAccountViewModel

  public init(viewModel: AppAccountViewModel) {
    _viewModel = .init(wrappedValue: viewModel)
  }

  public var body: some View {
    Group {
      if viewModel.isCompact {
        compactView
      } else {
        fullView
      }
    }
    .onAppear {
      Task {
        await viewModel.fetchAccount()
      }
    }
  }

  @ViewBuilder
  private var compactView: some View {
    HStack {
      if let account = viewModel.account {
        AvatarView(url: account.avatar)
      } else {
        ProgressView()
      }
    }
  }

  private var fullView: some View {
    HStack {
      if let account = viewModel.account {
        ZStack(alignment: .topTrailing) {
          AvatarView(url: account.avatar)
          if viewModel.appAccount.id == appAccounts.currentAccount.id {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.white, .green)
              .offset(x: 5, y: -5)
          } else if viewModel.showBadge,
                    let token = viewModel.appAccount.oauthToken,
                    let notificationsCount = preferences.getNotificationsCount(for: token),
                    notificationsCount > 0{
            ZStack {
              Circle()
                .fill(.red)
              Text(notificationsCount > 99 ? "99+" : String(notificationsCount))
                .foregroundColor(.white)
                .font(.system(size: 9))
            }
            .frame(width: 20, height: 20)
            .offset(x: 5, y: -5)
          }
        }
      } else {
        ProgressView()
        Text(viewModel.appAccount.accountName ?? viewModel.acct)
          .font(.scaledSubheadline)
          .foregroundColor(.gray)
          .padding(.leading, 6)
      }
      VStack(alignment: .leading) {
        if let account = viewModel.account {
          EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
          Text("\(account.username)@\(viewModel.appAccount.server)")
            .font(.scaledSubheadline)
            .emojiSize(Font.scaledSubheadlineFont.emojiSize)
            .emojiBaselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
            .foregroundColor(.gray)
        }
      }
      if viewModel.isInNavigation {
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundColor(.gray)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      if appAccounts.currentAccount.id == viewModel.appAccount.id,
         let account = viewModel.account
      {
        routerPath.navigate(to: .accountSettingsWithAccount(account: account, appAccount: viewModel.appAccount))
      } else {
        var transation = Transaction()
        transation.disablesAnimations = true
        withTransaction(transation) {
          appAccounts.currentAccount = viewModel.appAccount
        }
      }
    }
  }
}
