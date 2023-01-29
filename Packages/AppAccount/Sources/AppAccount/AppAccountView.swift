import DesignSystem
import EmojiText
import Env
import SwiftUI

public struct AppAccountView: View {
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject var appAccounts: AppAccountsManager
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
          }
        }
      } else {
        ProgressView()
      }
      VStack(alignment: .leading) {
        if let account = viewModel.account {
          EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
          Text("\(account.username)@\(viewModel.appAccount.server)")
            .font(.scaledSubheadline)
            .foregroundColor(.gray)
        }
      }
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.gray)
    }
    .onTapGesture {
      if appAccounts.currentAccount.id == viewModel.appAccount.id,
         let account = viewModel.account
      {
        routerPath.navigate(to: .accountSettingsWithAccount(account: account, appAccount: viewModel.appAccount))
      } else {
        appAccounts.currentAccount = viewModel.appAccount
      }
    }
  }
}
