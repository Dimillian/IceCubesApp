import SwiftUI
import Accounts
import Env
import DesignSystem
import TextView
import Models
import Network

public struct StatusEditorView: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel: StatusEditorViewModel
  
  public init(inReplyTo: Status?) {
    _viewModel = StateObject(wrappedValue: .init(inReplyTo: inReplyTo))
  }
  
  public var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        VStack {
          accountHeaderView
          TextView($viewModel.statusText)
            .placeholder("What's on your mind")
            .foregroundColor(.clear)
          Spacer()
        }
        accessoryView
          .padding(.bottom, 12)
      }
      .onAppear {
        viewModel.client = client
        viewModel.insertReplyTo()
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .navigationTitle("New post")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              _ = await viewModel.postStatus()
              dismiss()
            }
          } label: {
            Text("Post")
          }
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Text("Cancel")
          }
        }
      }
    }
  }
  
  @ViewBuilder private var accountHeaderView: some View {
    if let account = currentAccount.account {
      HStack {
        AvatarView(url: account.avatar, size: .status)
        VStack(alignment: .leading, spacing: 0) {
          account.displayNameWithEmojis
            .font(.subheadline)
            .fontWeight(.semibold)
          Text("@\(account.acct)")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        Spacer()
      }
    }
  }
  
  private var accessoryView: some View {
    HStack {
      Button {
        
      } label: {
        Image(systemName: "photo.fill.on.rectangle.fill")
      }
      Spacer()
    }
  }
    
}
