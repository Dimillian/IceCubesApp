import SwiftUI
import Models
import Routeur
import DesignSystem

public struct StatusRowView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var routeurPath: RouterPath
  
  private let status: Status
  private let isEmbed: Bool
  
  public init(status: Status, isEmbed: Bool = false) {
    self.status = status
    self.isEmbed = isEmbed
  }

  public var body: some View {
    VStack(alignment: .leading) {
      reblogView
      statusView
      StatusActionsView(status: status)
        .padding(.vertical, 8)
    }
  }
  
  @ViewBuilder
  private var reblogView: some View {
    if status.reblog != nil {
      HStack(spacing: 2) {
        Image(systemName:"arrow.left.arrow.right.circle")
        Text("\(status.account.displayName) reblogged")
      }
      .font(.footnote)
      .foregroundColor(.gray)
      .fontWeight(.semibold)
    }
  }
  
  @ViewBuilder
  private var statusView: some View {
    if let status: AnyStatus = status.reblog ?? status {
      if !isEmbed {
        Button {
          routeurPath.navigate(to: .accountDetailWithAccount(account: status.account))
        } label: {
          makeAccountView(status: status)
        }.buttonStyle(.plain)
      }
      
      Text(try! AttributedString(markdown: status.content.asMarkdown))
        .font(.body)
        .onTapGesture {
          routeurPath.navigate(to: .statusDetail(id: status.id))
        }
      
      if !status.mediaAttachments.isEmpty {
        StatusMediaPreviewView(attachements: status.mediaAttachments)
          .padding(.vertical, 4)
      }
    }
  }
  
  @ViewBuilder
  private func makeAccountView(status: AnyStatus) -> some View {
    AvatarView(url: status.account.avatar)
    VStack(alignment: .leading) {
      Text(status.account.displayName)
        .font(.headline)
      HStack {
        Text("@\(status.account.acct)")
          .font(.footnote)
          .foregroundColor(.gray)
        Spacer()
        Text(status.createdAt.formatted)
          .font(.footnote)
          .foregroundColor(.gray)
      }
    }
  }
}
