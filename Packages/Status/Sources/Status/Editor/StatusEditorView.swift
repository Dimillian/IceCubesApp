import SwiftUI
import Accounts
import Env
import DesignSystem
import TextView
import Models
import Network
import PhotosUI
import NukeUI

public struct StatusEditorView: View {
  @EnvironmentObject private var quicklook: QuickLook
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
        ScrollView {
          VStack(spacing: 12) {
            accountHeaderView
            TextView($viewModel.statusText)
              .placeholder("What's on your mind")
            if let status = viewModel.embededStatus {
              StatusEmbededView(status: status)
            }
            mediasView
            Spacer()
          }
        }
        accessoryView
          .padding(.bottom, 12)
      }
      .onAppear {
        viewModel.client = client
        viewModel.prepareStatusText()
        if !client.isAuth {
          dismiss()
        }
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
      HStack(spacing: 8) {
        ForEach(viewModel.mediasImages) { container in
          if let localImage = container.image {
            makeLocalImage(image: localImage)
          } else if let url = container.mediaAttachement?.url {
            ZStack(alignment: .topTrailing) {
              makeLazyImage(url: url)
              Button {
                withAnimation {
                  viewModel.mediasImages.removeAll(where: { $0.id == container.id })
                }
              } label: {
                Image(systemName: "xmark.circle")
              }
              .padding(8)
            }
          }
        }
      }
    }
  }
  
  private func makeLocalImage(image: UIImage) -> some View {
    ZStack(alignment: .center) {
      Image(uiImage: image)
        .resizable()
        .blur(radius: 20 )
        .aspectRatio(contentMode: .fill)
        .frame(width: 150, height: 150)
        .cornerRadius(8)
      
      ProgressView()
    }
  }
  
  private func makeLazyImage(url: URL?) -> some View {
    LazyImage(url: url) { state in
      if let image = state.image {
        image
          .resizingMode(.aspectFill)
          .frame(width: 150, height: 150)
      } else {
        Rectangle()
          .frame(width: 150, height: 150)
      }
    }
    .frame(width: 150, height: 150)
    .cornerRadius(8)
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
