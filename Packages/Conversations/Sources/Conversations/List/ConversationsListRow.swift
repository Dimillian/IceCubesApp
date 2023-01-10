import SwiftUI
import Models
import Accounts
import DesignSystem
import Env
import Network

struct ConversationsListRow: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  @EnvironmentObject private var theme: Theme
  
  let conversation: Conversation
  @ObservedObject var viewModel: ConversationsListViewModel
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top, spacing: 8) {
        AvatarView(url: conversation.accounts.first!.avatar)
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(conversation.accounts.map{ $0.safeDisplayName }.joined(separator: ", "))
              .font(.headline)
              .foregroundColor(theme.labelColor)
              .multilineTextAlignment(.leading)
            Spacer()
            if conversation.unread {
              Circle()
                .foregroundColor(theme.tintColor)
                .frame(width: 10, height: 10)
            }
            Text(conversation.lastStatus.createdAt.formatted)
              .font(.footnote)
          }
          Text(conversation.lastStatus.content.asRawText)
            .multilineTextAlignment(.leading)
        }
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture {
        Task {
          await viewModel.markAsRead(conversation: conversation)
        }
        routerPath.navigate(to: .statusDetail(id: conversation.lastStatus.id))
      }
      .padding(.top, 4)
      actionsView
        .padding(.bottom, 4)
    }
    .contextMenu {
      contextMenu
    }
  }
  
  private var actionsView: some View {
    HStack(spacing: 12) {
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(status: conversation.lastStatus)
      } label: {
        Image(systemName: "arrowshape.turn.up.left.fill")
      }
      Menu {
        contextMenu
      } label: {
        Image(systemName: "ellipsis")
          .frame(width: 30, height: 30)
          .contentShape(Rectangle())
      }
    }
    .padding(.leading, 48)
    .foregroundColor(.gray)
  }
  
  @ViewBuilder
  private var contextMenu: some View {
    Button {
      Task {
        await viewModel.markAsRead(conversation: conversation)
      }
    } label: {
      Label("Mark as read", systemImage: "eye")
    }
    
    Button(role: .destructive) {
      Task {
        await viewModel.delete(conversation: conversation)
      }
    } label: {
      Label("Delete", systemImage: "trash")
    }
  }
}
