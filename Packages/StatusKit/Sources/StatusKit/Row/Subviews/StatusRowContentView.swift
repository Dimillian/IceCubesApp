import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowContentView: View {
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.isCompact) private var isCompact
  @Environment(\.isStatusFocused) private var isFocused

  @Environment(Theme.self) private var theme

  var viewModel: StatusRowViewModel

  var body: some View {
    if !viewModel.finalStatus.spoilerText.asRawText.isEmpty {
      @Bindable var viewModel = viewModel
      StatusRowSpoilerView(status: viewModel.finalStatus, displaySpoiler: $viewModel.displaySpoiler)
    }

    if !viewModel.displaySpoiler {
      StatusRowTextView(viewModel: viewModel)
      if !reasons.contains(.placeholder) {
        StatusRowTranslateView(viewModel: viewModel)
      }
      if let poll = viewModel.finalStatus.poll {
        if #available(iOS 26.0, *) {
          StatusPollView(poll: poll, status: viewModel.finalStatus)
            .padding()
            .glassEffect(.regular.tint(theme.tintColor.opacity(0.1)),
                         in: RoundedRectangle(cornerRadius: 8))
        } else {
          StatusPollView(poll: poll, status: viewModel.finalStatus)
            .padding(.vertical)
        }
      }

      if !reasons.contains(.placeholder),
        !isCompact,
        viewModel.isEmbedLoading || viewModel.embeddedStatus != nil
      {
        if let embeddedStatus = viewModel.embeddedStatus {
          StatusEmbeddedView(
            status: embeddedStatus,
            client: viewModel.client,
            routerPath: viewModel.routerPath
          )
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity)
        } else {
          StatusEmbeddedView(
            status: Status.placeholder(),
            client: viewModel.client,
            routerPath: viewModel.routerPath
          )
          .fixedSize(horizontal: false, vertical: true)
          .redacted(reason: .placeholder)
          .transition(.opacity)
        }
      }

      if !viewModel.finalStatus.mediaAttachments.isEmpty {
        HStack {
          StatusRowMediaPreviewView(
            attachments: viewModel.finalStatus.mediaAttachments,
            sensitive: viewModel.finalStatus.sensitive)
          if theme.statusDisplayStyle == .compact {
            Spacer()
          }
        }
        .accessibilityHidden(isFocused == false)
        .padding(.vertical, 4)
      }

      if let card = viewModel.finalStatus.card,
        !viewModel.isEmbedLoading,
        !isCompact,
        theme.statusDisplayStyle != .compact,
        viewModel.embeddedStatus == nil,
        viewModel.finalStatus.mediaAttachments.isEmpty
      {
        StatusRowCardView(card: card)
      }
      
      // Display trailing tags if they were removed from content
      if viewModel.finalStatus.content.hadTrailingTags,
         !viewModel.finalStatus.tags.isEmpty {
        StatusRowTagsView(tags: viewModel.finalStatus.tags)
          .padding(.top, 8)
      }
    }
  }
}
