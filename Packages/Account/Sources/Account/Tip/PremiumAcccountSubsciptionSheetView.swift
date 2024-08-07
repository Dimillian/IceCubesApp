import SwiftUI
import Models
import Env
import DesignSystem
import WrappingHStack
import AppAccount
import Network

@MainActor
struct PremiumAcccountSubsciptionSheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme: Theme
  @Environment(\.openURL) private var openURL
  @Environment(AppAccountsManager.self) private var appAccount: AppAccountsManager
  @Environment(\.colorScheme) private var colorScheme
  
  @State private var isSubscibeSelected: Bool = false
  
  private enum SheetState: Int, Equatable {
    case selection, preparing, webview
  }
  
  @State private var state: SheetState = .selection
  @State private var animationsending: Bool = false
  @State private var subClubUser: SubClubUser?
  
  let account: Account
  let subClubClient = SubClubClient()
  
  var body: some View {
    VStack {
      switch state {
      case .selection:
        tipView
      case .preparing:
        preparingView
          .transition(.blurReplace)
      case .webview:
        webView
          .transition(.blurReplace)
      }
    }
    .presentationBackground(.thinMaterial)
    .presentationCornerRadius(8)
    .presentationDetents([.height(330)])
    .task {
      if let premiumUsername = account.premiumUsername {
        let user = await subClubClient.getUser(username: premiumUsername)
        withAnimation {
          subClubUser = user
        }
      }
    }
  }
  
  @ViewBuilder
  private var tipView: some View {
    HStack {
      Spacer()
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle")
          .font(.title3)
      }
      .padding(.trailing, 12)
      .padding(.top, 8)
    }
    VStack(alignment: .leading, spacing: 8) {
      Text("Subscribe")
        .font(.title2)
      Text("Subscribe to @\(account.username) to get access to exclusive content!")
      if let subscription = subClubUser?.subscription {
        Button {
          withAnimation(.easeInOut(duration: 0.5)) {
            isSubscibeSelected = true
          }
        } label: {
          Text("\(subscription.formattedAmount) / month")
        }
        .buttonStyle(.borderedProminent)
        .padding(.vertical, 8)
      } else {
        ProgressView()
          .foregroundStyle(theme.labelColor)
          .padding(.vertical, 8)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.secondaryBackgroundColor.opacity(0.4))
    .cornerRadius(8)
    .padding(12)
    
    Spacer()
    
    if isSubscibeSelected {
      Button {
        withAnimation {
          state = .preparing
        }
      } label: {
        Text("Subscribe")
          .font(.headline)
          .fontWeight(.bold)
          .frame(maxWidth: .infinity)
          .frame(height: 40)
      }
      .buttonStyle(.borderedProminent)
      .padding(.horizontal, 16)
      .padding(.bottom, 38)
    }
  }
  
  private var preparingView: some View {
    Label("Preparing...", systemImage: "wifi")
      .symbolEffect(.variableColor.iterative, options: .repeating, value: animationsending)
      .font(.title)
      .fontWeight(.bold)
      .onAppear {
        animationsending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
          dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          withAnimation {
            state = .webview
          }
        }
      }
  }
  
  private var webView: some View {
    VStack(alignment: .center) {
      Text("Almost there...")
    }
    .font(.title)
    .fontWeight(.bold)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let subscription = subClubUser?.subscription,
           let accountName = appAccount.currentAccount.accountName,
           let premiumUsername = account.premiumUsername,
           let url = URL(string: "https://\(AppInfo.premiumInstance)/@\(premiumUsername)/subscribe?callback=icecubesapp://subclub&id=@\(accountName)&amount=\(subscription.unitAmount)&currency=\(subscription.currency)&theme=\(colorScheme)") {
          openURL(url)
        }
      }
    }
  }
}
