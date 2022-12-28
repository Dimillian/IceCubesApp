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
  @EnvironmentObject private var currentInstance: CurrentInstance
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
          Divider()
          VStack(spacing: 12) {
            accountHeaderView
              .padding(.horizontal, DS.Constants.layoutPadding)
            TextView($viewModel.statusText, $viewModel.selectedRange)
              .placeholder("What's on your mind")
              .padding(.horizontal, DS.Constants.layoutPadding)
            if let status = viewModel.embededStatus {
              StatusEmbededView(status: status)
                .padding(.horizontal, DS.Constants.layoutPadding)
            }
            mediasView
            Spacer()
          }
          .padding(.top, 8)
        }
        accessoryView
      }
      .onAppear {
        viewModel.client = client
        viewModel.prepareStatusText()
        if !client.isAuth {
          dismiss()
        }
      }
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
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(viewModel.mediasImages) { container in
          if container.image != nil {
            makeLocalImage(container: container)
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
      .padding(.horizontal, DS.Constants.layoutPadding)
    }
  }
  
  private func makeLocalImage(container: StatusEditorViewModel.ImageContainer) -> some View {
    ZStack(alignment: .center) {
      Image(uiImage: container.image!)
        .resizable()
        .blur(radius: 20 )
        .aspectRatio(contentMode: .fill)
        .frame(width: 150, height: 150)
        .cornerRadius(8)
      if container.error != nil {
        VStack {
          Text("Error uploading")
          Button {
            withAnimation {
              viewModel.mediasImages.removeAll(where: { $0.id == container.id })
            }
          } label: {
            VStack {
              Text("Delete")
            }
          }
          .buttonStyle(.bordered)
          Button {
            Task {
              await viewModel.upload(container: container)
            }
          } label: {
            VStack {
              Text("Retry")
            }
          }
          .buttonStyle(.bordered)
        }
      } else {
        ProgressView()
      }
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
    VStack(spacing: 0) {
      Divider()
      HStack(spacing: 16) {
        PhotosPicker(selection: $viewModel.selectedMedias,
                     matching: .images) {
          Image(systemName: "photo.fill.on.rectangle.fill")
        }
        
        Button {
          viewModel.insertStatusText(text: " @")
        } label: {
          Image(systemName: "at")
        }
        
        Button {
          viewModel.insertStatusText(text: " #")
        } label: {
          Image(systemName: "number")
        }
        
        visibilityMenu

        Spacer()
        
        characterCountView
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial)
    }
  }
  
  private var characterCountView: some View {
    Text("\((currentInstance.instance?.configuration.statuses.maxCharacters ?? 500) - viewModel.statusText.string.utf16.count)")
      .foregroundColor(.gray)
      .font(.callout)
  }
  
  private var visibilityMenu: some View {
    Menu {
      ForEach(Models.Visibility.allCases, id: \.self) { visibility in
        Button {
          viewModel.visibility = visibility
        } label: {
          Label(visibility.title, systemImage: visibility.iconName)
        }
      }
    } label: {
      Image(systemName: viewModel.visibility.iconName)
    }

  }
    
}
