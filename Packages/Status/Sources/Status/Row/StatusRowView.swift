import SwiftUI
import Models
import Routeur
import DesignSystem
import Network

public struct StatusRowView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  @StateObject var viewModel: StatusRowViewModel
  
  public init(viewModel: StatusRowViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    VStack(alignment: .leading) {
      reblogView
      statusView
      StatusActionsView(viewModel: viewModel)
        .padding(.vertical, 8)
    }
    .onAppear {
      viewModel.client = client
    }
  }
  
  @ViewBuilder
  private var reblogView: some View {
    if viewModel.status.reblog != nil {
      HStack(spacing: 2) {
        Image(systemName:"arrow.left.arrow.right.circle")
        Text("\(viewModel.status.account.displayName) reblogged")
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
    }
  }
  
  private var statusView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let status: AnyStatus = viewModel.status.reblog ?? viewModel.status {
        if !viewModel.isEmbed {
          Button {
            routeurPath.navigate(to: .accountDetailWithAccount(account: status.account))
          } label: {
            makeAccountView(status: status)
          }.buttonStyle(.plain)
        }
        
        Text(status.content.asSafeAttributedString)
          .font(.body)
          .onTapGesture {
            routeurPath.navigate(to: .statusDetail(id: status.id))
          }
          .environment(\.openURL, OpenURLAction { url in
            routeurPath.handleStatus(status: status, url: url)
          })
        
        if !status.mediaAttachments.isEmpty {
          StatusMediaPreviewView(attachements: status.mediaAttachments)
            .padding(.vertical, 4)
        }
        StatusCardView(status: status)
      }
    }
  }
  
  @ViewBuilder
  private func makeAccountView(status: AnyStatus) -> some View {
    AvatarView(url: status.account.avatar)
    VStack(alignment: .leading) {
      Text(status.account.displayName)
        .font(.subheadline)
        .fontWeight(.semibold)
      Group {
        Text("@\(status.account.acct)") +
        Text(" ⸱ ") +
        Text(status.createdAt.formatted)
      }
      .font(.footnote)
      .foregroundColor(.gray)
    }
  }
}
