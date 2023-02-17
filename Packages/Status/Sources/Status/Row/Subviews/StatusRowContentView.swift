import SwiftUI
import DesignSystem
import Models
import Env

struct StatusRowContentView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact
  
  @EnvironmentObject private var theme: Theme
  
  let status: AnyStatus
  @ObservedObject var viewModel: StatusRowViewModel
  
  var body: some View {
    if !status.spoilerText.asRawText.isEmpty {
      StatusRowSpoilerView(status: status, displaySpoiler: $viewModel.displaySpoiler)
    }

    if !viewModel.displaySpoiler {
      StatusRowTextView(status: status, viewModel: viewModel)
      StatusRowTranslateView(status: status, viewModel: viewModel)
      if let poll = status.poll {
        StatusPollView(poll: poll, status: status)
      }

      if !reasons.contains(.placeholder),
         !isCompact,
          (viewModel.isEmbedLoading || viewModel.embeddedStatus != nil) {
        StatusEmbeddedView(status: viewModel.embeddedStatus ?? Status.placeholder(),
                           client: viewModel.client,
                           routerPath: viewModel.routerPath)
          .fixedSize(horizontal: false, vertical: true)
          .redacted(reason: viewModel.isEmbedLoading ? .placeholder : [])
          .shimmering(active: viewModel.isEmbedLoading)
          .transition(.opacity)
      }
      
      if !status.mediaAttachments.isEmpty {
        HStack {
          StatusRowMediaPreviewView(attachments: status.mediaAttachments,
                                    sensitive: status.sensitive,
                                    isNotifications: isCompact)
          if theme.statusDisplayStyle == .compact {
            Spacer()
          }
        }
        .padding(.vertical, 4)
      }
      
      if let card = status.card,
         !viewModel.isEmbedLoading,
         !isCompact,
         theme.statusDisplayStyle == .large,
         status.content.statusesURLs.isEmpty,
         status.mediaAttachments.isEmpty
      {
        StatusRowCardView(card: card)
      }
    }
  }
}
