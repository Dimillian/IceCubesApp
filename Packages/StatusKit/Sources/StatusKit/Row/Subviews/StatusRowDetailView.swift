import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct StatusRowDetailView: View {
  @Environment(\.openURL) private var openURL

  @Environment(StatusDataController.self) private var statusDataController

  var viewModel: StatusRowViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Divider()
      HStack {
        Group {
          Text(viewModel.status.createdAt.asDate, style: .date) +
            Text("status.summary.at-time") +
            Text(viewModel.status.createdAt.asDate, style: .time) +
            Text("  ·")
          Image(systemName: viewModel.status.visibility.iconName)
            .accessibilityHidden(true)
        }.accessibilityElement(children: .combine)
        Spacer()
        if let name = viewModel.status.application?.name, let url = viewModel.status.application?.website {
          Button {
            openURL(url)
          } label: {
            Text(name)
              .underline()
          }
          .buttonStyle(.plain)
          .accessibilityLabel("accessibility.status.application.label")
          .accessibilityValue(name)
          .accessibilityAddTraits(.isLink)
          .accessibilityRemoveTraits(.isButton)
        }
      }
      .font(.scaledCaption)
      .foregroundStyle(.secondary)

      if let editedAt = viewModel.status.editedAt {
        Divider()
        HStack {
          Text("status.summary.edited-time") +
            Text(editedAt.asDate, style: .date) +
            Text("status.summary.at-time") +
            Text(editedAt.asDate, style: .time)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
          viewModel.routerPath.presentedSheet = .statusEditHistory(status: viewModel.status.id)
        }
        .underline()
        .font(.scaledCaption)
        .foregroundStyle(.secondary)
      }

      if viewModel.actionsAccountsFetched, statusDataController.favoritesCount > 0 {
        Divider()
        Button {
          viewModel.routerPath.navigate(to: .favoritedBy(id: viewModel.status.id))
        } label: {
          HStack {
            Text("status.summary.n-favorites \(statusDataController.favoritesCount)")
              .font(.scaledCallout)
            Spacer()
            makeAccountsScrollView(accounts: viewModel.favoriters)
            Image(systemName: "chevron.right")
          }
          .frame(height: 20)
        }
        .buttonStyle(.borderless)
        .transition(.move(edge: .leading))
      }

      if viewModel.actionsAccountsFetched, statusDataController.reblogsCount > 0 {
        Divider()
        Button {
          viewModel.routerPath.navigate(to: .rebloggedBy(id: viewModel.status.id))
        } label: {
          HStack {
            Text("status.summary.n-boosts \(statusDataController.reblogsCount)")
              .font(.scaledCallout)
            Spacer()
            makeAccountsScrollView(accounts: viewModel.rebloggers)
            Image(systemName: "chevron.right")
          }
          .frame(height: 20)
        }
        .buttonStyle(.borderless)
        .transition(.move(edge: .leading))
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
          AvatarView(account.avatar, config: .list)
            .padding(.leading, -4)
        }
        .transition(.opacity)
      }
      .padding(.leading, .layoutPadding)
    }
  }
}
