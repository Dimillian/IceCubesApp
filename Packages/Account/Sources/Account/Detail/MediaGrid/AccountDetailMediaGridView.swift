import DesignSystem
import Env
import MediaUI
import Models
import NetworkClient
import NukeUI
import SwiftUI

@MainActor
public struct AccountDetailMediaGridView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Environment(MastodonClient.self) private var client
  @Environment(QuickLook.self) private var quickLook

  let account: Account
  @State var mediaStatuses: [MediaStatus]

  public init(account: Account, initialMediaStatuses: [MediaStatus]) {
    self.account = account
    mediaStatuses = initialMediaStatuses
  }

  public var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(
        columns: [
          .init(.flexible(minimum: 100), spacing: 4),
          .init(.flexible(minimum: 100), spacing: 4),
          .init(.flexible(minimum: 100), spacing: 4),
        ],
        spacing: 4
      ) {
        ForEach(mediaStatuses) { status in
          GeometryReader { proxy in
            if let url = status.attachment.url {
              Group {
                switch status.attachment.supportedType {
                case .image:
                  LazyImage(url: url, transaction: Transaction(animation: .easeIn)) { state in
                    if let image = state.image {
                      image
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.width)
                    } else {
                      ProgressView()
                        .frame(width: proxy.size.width, height: proxy.size.width)
                    }
                  }
                  .processors([.resize(size: proxy.size)])
                  .transition(.opacity)
                case .gifv, .video:
                  MediaUIAttachmentVideoView(viewModel: .init(url: url))
                case .none:
                  EmptyView()
                case .some(.audio):
                  EmptyView()
                }
              }
              .onTapGesture {
                routerPath.navigate(to: .statusDetailWithStatus(status: status.status))
              }
              .contextMenu {
                Button {
                  quickLook.prepareFor(
                    selectedMediaAttachment: status.attachment,
                    mediaAttachments: status.status.mediaAttachments)
                } label: {
                  Label("Open Media", systemImage: "photo")
                }
                MediaUIShareLink(
                  url: url, type: status.attachment.supportedType == .image ? .image : .av)
                Button {
                  Task {
                    let transferable = MediaUIImageTransferable(url: url)
                    UIPasteboard.general.image = UIImage(data: await transferable.fetchData())
                  }
                } label: {
                  Label("status.media.contextmenu.copy", systemImage: "doc.on.doc")
                }
                Button {
                  UIPasteboard.general.url = url
                } label: {
                  Label("status.action.copy-link", systemImage: "link")
                }
              }
            }
          }
          .clipped()
          .aspectRatio(1, contentMode: .fit)
        }

        VStack {
          Spacer()
          NextPageView {
            try await fetchNextPage()
          }
          Spacer()
        }
      }
    }
    .navigationTitle(account.displayName ?? "")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
  }

  private func fetchNextPage() async throws {
    let newStatuses: [Status] =
      try await client.get(
        endpoint: Accounts.statuses(
          id: account.id,
          sinceId: mediaStatuses.last?.id,
          tag: nil,
          onlyMedia: true,
          excludeReplies: true,
          excludeReblogs: true,
          pinned: nil))
    mediaStatuses.append(contentsOf: newStatuses.flatMap { $0.asMediaStatus })
  }
}
