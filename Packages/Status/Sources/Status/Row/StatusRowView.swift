import SwiftUI
import Models
import Routeur
import DesignSystem
import Network

public struct StatusRowView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var client: Client
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
      makeCardView(status: status)
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
  
  @ViewBuilder
  private func makeCardView(status: AnyStatus) -> some View {
    if let card = status.card, let title = card.title {
      VStack(alignment: .leading) {
        if let imageURL = card.image {
          AsyncImage(
            url: imageURL,
            content: { image in
              image.resizable()
                .aspectRatio(contentMode: .fill)
            },
            placeholder: {
              ProgressView()
                .frame(maxWidth: 40, maxHeight: 40)
            }
          )
        }
        Spacer()
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text(title)
              .font(.headline)
              .lineLimit(3)
            if let description = card.description, !description.isEmpty {
              Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            } else {
              Text(card.url.absoluteString)
                .font(.body)
                .foregroundColor(.gray)
                .lineLimit(3)
            }
          }
          Spacer()
        }.padding(8)
      }
      .background(Color.gray.opacity(0.15))
      .cornerRadius(16)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(.gray.opacity(0.35), lineWidth: 1)
      )
      .onTapGesture {
        openURL(card.url)
      }
    }
  }
}
