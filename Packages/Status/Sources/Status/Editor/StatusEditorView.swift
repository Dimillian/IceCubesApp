import SwiftUI
import Accounts
import Env
import DesignSystem
import TextView

public struct StatusEditorView: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel = StatusEditorViewModel()
  
  public init() {
    
  }
  
  public var body: some View {
    NavigationStack {
      VStack {
        accountHeaderView
        TextView($viewModel.statusText)
          .placeholder("What's on your mind")
          .foregroundColor(.clear)
        Spacer()
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .navigationTitle("New post")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
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
    
}
