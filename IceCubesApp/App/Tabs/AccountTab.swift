import SwiftUI
import Env
import Network
import Account
import Models
import Shimmer

struct AccountTab: View {
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @State private var loggedUser: Account?
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      if let loggedUser {
        AccountDetailView(account: loggedUser, isCurrentUser: true)
          .withAppRouteur()
          .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
      } else {
        AccountDetailView(account: .placeholder())
          .redacted(reason: .placeholder)
          .shimmering()
      }
    }
    .onAppear {
      Task {
        await fetchUser(client: client)
      }
    }
    .onChange(of: client) { newClient in
      Task {
        await fetchUser(client: newClient)
      }
    }
    .environmentObject(routeurPath)
  }
  
  
  private func fetchUser(client: Client) async {
    guard client.isAuth else { return }
    Task {
      loggedUser = try? await client.get(endpoint: Accounts.verifyCredentials)
    }
  }
}
