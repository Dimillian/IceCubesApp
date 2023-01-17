import Env
import Foundation
import SwiftUI

struct StatusRowContextMenu: View {
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var routerPath: RouterPath

  @Environment(\.openURL) var openURL

  @ObservedObject var viewModel: StatusRowViewModel

  var body: some View {
    if !viewModel.isRemote {
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
      Button { Task {
        if viewModel.isBookmarked {
          await viewModel.unbookmark()
        } else {
          await viewModel.bookmark()
        }
      } } label: {
        Label(viewModel.isReblogged ? "Unbookmark" : "Bookmark",
              systemImage: "bookmark")
      }
      Button {
        routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
      } label: {
        Label("Reply", systemImage: "arrowshape.turn.up.left")
      }
    }

    if viewModel.status.visibility == .pub, !viewModel.isRemote {
      Button {
        routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
      } label: {
        Label("Quote this post", systemImage: "quote.bubble")
      }
    }

    Divider()

    if let url = viewModel.status.reblog?.url ?? viewModel.status.url {
      ShareLink(item: url) {
        Label("Share this post", systemImage: "square.and.arrow.up")
      }
    }

    if let url = viewModel.status.reblog?.url ?? viewModel.status.url {
      Button { openURL(url) } label: {
        Label("View in Browser", systemImage: "safari")
      }
    }

    Button {
      UIPasteboard.general.string = viewModel.status.content.asRawText
    } label: {
      Label("Copy Text", systemImage: "doc.on.doc")
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
          Label(viewModel.isPinned ? "Unpin" : "Pin", systemImage: viewModel.isPinned ? "pin.fill" : "pin")
        }
        Button {
          routerPath.presentedSheet = .editStatusEditor(status: viewModel.status)
        } label: {
          Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) { Task { await viewModel.delete() } } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    } else if !viewModel.isRemote {
      Section(viewModel.status.account.acct) {
        Button {
          routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .pub)
        } label: {
          Label("Mention", systemImage: "at")
        }
        Button {
          routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .direct)
        } label: {
          Label("Message", systemImage: "tray.full")
        }
      }
    }
  }
}
