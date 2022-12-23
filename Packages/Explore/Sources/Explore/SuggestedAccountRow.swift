import SwiftUI
import Models
import Network
import DesignSystem
import Env

@MainActor
class SuggestedAccountViewModel: ObservableObject {
  var client: Client?
  
  @Published var account: Account
  @Published var relationShip: Relationshionship
  
  init(account: Account, relationShip: Relationshionship) {
    self.account = account
    self.relationShip = relationShip
  }
  
  func follow() async {
    guard let client else { return }
    do {
      self.relationShip = try await client.post(endpoint: Accounts.follow(id: account.id))
    } catch {}
  }
  
  func unfollow() async {
    guard let client else { return }
    do {
      self.relationShip = try await client.post(endpoint: Accounts.unfollow(id: account.id))
    } catch {}
  }
}

struct SuggestedAccountRow: View {
  @EnvironmentObject private var routeurPath: RouterPath
  @EnvironmentObject private var client: Client
  
  @StateObject var viewModel: SuggestedAccountViewModel
  
  var body: some View {
    HStack(alignment: .top) {
      AvatarView(url: viewModel.account.avatar, size: .status)
      VStack(alignment: .leading, spacing: 2) {
        viewModel.account.displayNameWithEmojis
          .font(.subheadline)
          .fontWeight(.semibold)
        Text("@\(viewModel.account.acct)")
          .font(.footnote)
          .foregroundColor(.gray)
        Text(viewModel.account.note.asSafeAttributedString)
          .font(.callout)
          .environment(\.openURL, OpenURLAction { url in
            routeurPath.handle(url: url)
          })
      }
      Spacer()
      Button {
        Task {
          if viewModel.relationShip.following {
            await viewModel.unfollow()
          } else {
            await viewModel.follow()
          }
        }
      } label: {
        if viewModel.relationShip.requested {
          Text("Requested")
            .font(.callout)
        } else {
          Text(viewModel.relationShip.following ? "Unfollow" : "Follow")
            .font(.callout)
        }
      }
      .buttonStyle(.bordered)
    }
    .onAppear {
      viewModel.client = client
    }
    .onTapGesture {
      routeurPath.navigate(to: .accountDetailWithAccount(account: viewModel.account))
    }
  }
}
