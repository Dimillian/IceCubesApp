import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowContentView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact

  @EnvironmentObject private var theme: Theme

  @ObservedObject var viewModel: StatusRowViewModel

  var body: some View {
    if !viewModel.finalStatus.spoilerText.asRawText.isEmpty {
      StatusRowSpoilerView(status: viewModel.finalStatus, displaySpoiler: $viewModel.displaySpoiler)
    }

    if !viewModel.displaySpoiler {
      StatusRowTextView(viewModel: viewModel)
      StatusRowTranslateView(viewModel: viewModel)
      if let poll = viewModel.finalStatus.poll {
        StatusPollView(poll: poll, status: viewModel.finalStatus)
      }

      if !reasons.contains(.placeholder),
         !isCompact,
         viewModel.isEmbedLoading || viewModel.embeddedStatus != nil
      {
        StatusEmbeddedView(status: viewModel.embeddedStatus ?? Status.placeholder(),
                           client: viewModel.client,
                           routerPath: viewModel.routerPath)
          .fixedSize(horizontal: false, vertical: true)
          .redacted(reason: viewModel.isEmbedLoading ? .placeholder : [])
          .shimmering(active: viewModel.isEmbedLoading)
          .transition(.opacity)
      }

      if !viewModel.finalStatus.mediaAttachments.isEmpty {
        HStack {
          StatusRowMediaPreviewView(attachments: viewModel.finalStatus.mediaAttachments,
                                    sensitive: viewModel.finalStatus.sensitive,
                                    isNotifications: isCompact)
          if theme.statusDisplayStyle == .compact {
            Spacer()
          }
        }
        .padding(.vertical, 4)
      }

      if let card = viewModel.finalStatus.card,
         !viewModel.isEmbedLoading,
         !isCompact,
         theme.statusDisplayStyle != .compact,
         viewModel.finalStatus.content.statusesURLs.isEmpty,
         viewModel.finalStatus.mediaAttachments.isEmpty
      {
        StatusRowCardView(card: card)
      }
    }
  }
}
