import SwiftUI
import Accounts
import Env
import DesignSystem
import TextView
import Models
import Network
import PhotosUI

public struct StatusEditorView: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel: StatusEditorViewModel
  
  public init(mode: StatusEditorViewModel.Mode) {
    _viewModel = StateObject(wrappedValue: .init(mode: mode))
  }
  
  public var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        VStack(spacing: 12) {
          accountHeaderView
          TextView($viewModel.statusText)
            .placeholder("What's on your mind")
          mediasView
          Spacer()
        }
        accessoryView
          .padding(.bottom, 12)
      }
      .onAppear {
        viewModel.client = client
        viewModel.prepareStatusText()
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .navigationTitle(viewModel.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              let status = await viewModel.postStatus()
              if status != nil {
                dismiss()
              }
            }
          } label: {
            if viewModel.isPosting {
              ProgressView()
            } else {
              Text("Post")
            }
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
  
  @ViewBuilder
  private var accountHeaderView: some View {
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
  
  private var mediasView: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(viewModel.mediasImages) { container in
          Image(uiImage: container.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .clipped()
        }
      }
    }
  }
  
  private var accessoryView: some View {
    HStack {
      PhotosPicker(selection: $viewModel.selectedMedias,
                   matching: .images) {
        Image(systemName: "photo.fill.on.rectangle.fill")
      }
      Spacer()
    }
  }
    
}
