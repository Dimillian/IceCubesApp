import SwiftUI
import Models
import Env
import DesignSystem
import WrappingHStack
import AppAccount

@MainActor
struct PremiumAcccountSubsciptionSheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme: Theme
  @Environment(\.openURL) private var openURL
  @Environment(AppAccountsManager.self) private var appAccount: AppAccountsManager
  
  @State private var isSubscibeSelected: Bool = false
  
  private enum SheetState: Int, Equatable {
    case selection, preparing, webview
  }
  
  @State private var state: SheetState = .selection
  @State private var animationsending: Bool = false
  
  let account: Account
  
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
      Button {
        withAnimation(.easeInOut(duration: 0.5)) {
          isSubscibeSelected = true
        }
      } label: {
        Text("$5 / month")
      }
      .buttonStyle(.borderedProminent)
      .padding(.vertical, 8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(theme.secondaryBackgroundColor.opacity(0.4))
    .cornerRadius(8)
    .padding(12)
    
    Spacer()
    
    if isSubscibeSelected {
      HStack(alignment: .top) {
        Text("Subscribe")
          .font(.headline)
          .fontWeight(.bold)
      }
      .transition(.push(from: .bottom))
      .frame(height: 50)
      .frame(maxWidth: .infinity)
      .background(theme.tintColor.opacity(0.5))
      .onTapGesture {
        withAnimation {
          state = .preparing
        }
      }
      .ignoresSafeArea()
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
        if let accountName = appAccount.currentAccount.accountName,
           let premiumUsername = account.premiumUsername,
           let url = URL(string: "https://\(AppInfo.premiumInstance)/subscribe/to/\(premiumUsername)?callback=icecubesapp://socialproxy&id=@\(accountName)&amount=\(500)&currency=USD") {
          openURL(url)
        }
      }
    }
  }
}
