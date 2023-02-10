import SwiftUI
import Env
import DesignSystem
import Models

struct StatusRowDetailView: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var routerPath: RouterPath
  
  @ObservedObject var viewModel: StatusRowViewModel
  
  var body: some View {
    Group {
      Divider()
      HStack {
        Text(viewModel.status.createdAt.asDate, style: .date) +
          Text("status.summary.at-time") +
          Text(viewModel.status.createdAt.asDate, style: .time) +
          Text("  ·")
        Image(systemName: viewModel.status.visibility.iconName)
        Spacer()
        Text(viewModel.status.application?.name ?? "")
          .underline()
          .onTapGesture {
            if let url = viewModel.status.application?.website {
              openURL(url)
            }
          }
      }
      .font(.scaledCaption)
      .foregroundColor(.gray)

      if let editedAt = viewModel.status.editedAt {
        Divider()
        HStack {
          Text("status.summary.edited-time") +
            Text(editedAt.asDate, style: .date) +
            Text("status.summary.at-time") +
            Text(editedAt.asDate, style: .time)
          Spacer()
        }
        .onTapGesture {
          routerPath.presentedSheet = .statusEditHistory(status: viewModel.status.id)
        }
        .underline()
        .font(.scaledCaption)
        .foregroundColor(.gray)
      }

      if viewModel.favoritesCount > 0 {
        Divider()
        NavigationLink(value: RouterDestinations.favoritedBy(id: viewModel.status.id)) {
          HStack {
            Text("status.summary.n-favorites \(viewModel.favoritesCount)")
              .font(.scaledCallout)
            Spacer()
            makeAccountsScrollView(accounts: viewModel.favoriters)
            Image(systemName: "chevron.right")
          }
          .frame(height: 20)
        }
      }
      if viewModel.reblogsCount > 0 {
        Divider()
        NavigationLink(value: RouterDestinations.rebloggedBy(id: viewModel.status.id)) {
          HStack {
            Text("status.summary.n-boosts \(viewModel.reblogsCount)")
              .font(.scaledCallout)
            Spacer()
            makeAccountsScrollView(accounts: viewModel.rebloggers)
            Image(systemName: "chevron.right")
          }
          .frame(height: 20)
        }
      }
    }
    .task {
      await viewModel.fetchActionsAccounts()
    }
  }
  
  private func makeAccountsScrollView(accounts: [Account]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEach(accounts) { account in
          AvatarView(url: account.avatar, size: .list)
            .padding(.leading, -4)
        }
      }
      .padding(.leading, .layoutPadding)
    }
  }

}
