import SwiftUI
import Env
import Models
import DesignSystem
import NukeUI

struct StatusEditorMediaView: View {
  @ObservedObject var viewModel: StatusEditorViewModel
  
  var body: some View {
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
    
}
