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
        KTagWithRelationListView(viewModel: KTagWithRelationListViewModel.init(statusId: viewModel.status.id, kTagRelations: viewModel.status.kTagRelations, addingKTagRelations: viewModel.status.kTagAddRealationRequests), client: viewModel.client)
        NavigationLink(destination: KTagSearchAndAddView( viewModel: KTagWithRelationListViewModel.init(client:  viewModel.client, statusId: viewModel.status.id, kTagRelations: viewModel.status.kTagRelations , addingKTagRelations: viewModel.status.kTagAddRealationRequests), client: viewModel.client)) {
          Text("追加")
              .foregroundColor(.white)
              .padding()
              .background(Color.blue)
              .cornerRadius(8)
        }
    if !viewModel.displaySpoiler {
      StatusRowTextView(viewModel: viewModel)
      if !reasons.contains(.placeholder) {
        StatusRowTranslateView(viewModel: viewModel)
      }
      if let poll = viewModel.finalStatus.poll {
        StatusPollView(poll: poll, status: viewModel.finalStatus)
      }

      if !reasons.contains(.placeholder),
         !isCompact,
         viewModel.isEmbedLoading || viewModel.embeddedStatus != nil
      {
        if let embeddedStatus = viewModel.embeddedStatus {
          StatusEmbeddedView(status: embeddedStatus,
                             client: viewModel.client,
                             routerPath: viewModel.routerPath)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity)
        } else {
          StatusEmbeddedView(status: Status.placeholder(),
                             client: viewModel.client,
                             routerPath: viewModel.routerPath)
            .fixedSize(horizontal: false, vertical: true)
            .redacted(reason: .placeholder)
            .transition(.opacity)
        }
      }

      if !viewModel.finalStatus.mediaAttachments.isEmpty {
        HStack {
          StatusRowMediaPreviewView(attachments: viewModel.finalStatus.mediaAttachments,
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
    }
  }
}
