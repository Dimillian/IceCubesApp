import Foundation
import SwiftUI
import Env

struct StatusRowContextMenu: View {
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var routeurPath: RouterPath
  @ObservedObject var viewModel: StatusRowViewModel
  
  var body: some View {
    Button { Task {
      if viewModel.isFavourited {
        await viewModel.unFavourite()
      } else {
        await viewModel.favourite()
      }
    } } label: {
      Label(viewModel.isFavourited ? "Unfavorite" : "Favorite", systemImage: "star")
    }
    Button { Task {
      if viewModel.isReblogged {
        await viewModel.unReblog()
      } else {
        await viewModel.reblog()
      }
    } } label: {
      Label(viewModel.isReblogged ? "Unboost" : "Boost", systemImage: "arrow.left.arrow.right.circle")
    }
    
    if viewModel.status.visibility == .pub {
      Button {
        routeurPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
      } label: {
        Label("Quote this post", systemImage: "quote.bubble")
      }
    }
    
    if let url = viewModel.status.reblog?.url ?? viewModel.status.url {
      Button { UIApplication.shared.open(url)  } label: {
        Label("View in Browser", systemImage: "safari")
      }
    }

    if account.account?.id == viewModel.status.account.id {
      Section("Your post") {
        Button {
          Task {
            if viewModel.isPinned {
              await viewModel.unPin()
            } else {
              await viewModel.pin()
            }
          }
        } label: {
          Label(viewModel.isPinned ? "Unpin": "Pin", systemImage: viewModel.isPinned ? "pin.fill" : "pin")
        }
        Button {
          routeurPath.presentedSheet = .editStatusEditor(status: viewModel.status)
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) { Task { await viewModel.delete() } } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    } else {
      Section(viewModel.status.account.acct) {
        Button {
          routeurPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .pub)
        } label: {
          Label("Mention", systemImage: "at")
        }
        Button {
          routeurPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .direct)
        } label: {
          Label("Message", systemImage: "tray.full")
        }
      }
    }
  }
}
