import SwiftUI
import Models
import Env
import Shimmer
import Nuke
import NukeUI
import DesignSystem

public struct StatusMediaPreviewView: View {
  @EnvironmentObject private var quickLook: QuickLook
  
  public let attachements: [MediaAttachement]

  @State private var isQuickLookLoading: Bool = false
  @State private var width: CGFloat = 0
  
  private var imageMaxHeight: CGFloat {
    if attachements.count == 1 {
      return 300
    }
    return attachements.count > 2 ? 100 : 200
  }
  
  private func size(for media: MediaAttachement) -> CGSize? {
    if let width = media.meta?.original.width,
       let height = media.meta?.original.height {
      return .init(width: CGFloat(width), height: CGFloat(height))
    }
    return nil
  }
  
  private func imageSize(from: CGSize, newWidth: CGFloat) -> CGSize {
    let ratio = newWidth / from.width
    let newHeight = from.height * ratio
    return .init(width: newWidth, height: newHeight)
  }
  
  public var body: some View {
    Group {
      if attachements.count == 1, let attachement = attachements.first {
        makeFeaturedImagePreview(attachement: attachement)
          .onTapGesture {
            Task {
              await quickLook.prepareFor(urls: attachements.map{ $0.url }, selectedURL: attachement.url)
            }
          }
      } else {
        VStack {
          HStack {
            if let firstAttachement = attachements.first {
              makePreview(attachement: firstAttachement)
            }
            if attachements.count > 1, let secondAttachement = attachements[1] {
              makePreview(attachement: secondAttachement)
            }
          }
          HStack {
            if attachements.count > 2, let secondAttachement = attachements[2] {
              makePreview(attachement: secondAttachement)
            }
            if attachements.count > 3, let secondAttachement = attachements[3] {
              makePreview(attachement: secondAttachement)
            }
          }
        }
      }
    }
    .overlay {
      if quickLook.isPreparing {
        quickLookLoadingView
          .transition(.opacity)
      }
    }
  }
  
  @ViewBuilder
  private func makeFeaturedImagePreview(attachement: MediaAttachement) -> some View {
    switch attachement.supportedType {
    case .image:
      if let size = size(for: attachement) {
        let newSize = imageSize(from: size,
                                newWidth: UIScreen.main.bounds.width - (DS.Constants.layoutPadding * 2))
        LazyImage(url: attachement.url) { state in
          if let image = state.image {
            image
              .resizingMode(.aspectFill)
              .cornerRadius(4)
              .frame(width: newSize.width, height: newSize.height)
          } else {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.gray)
              .frame(width: newSize.width, height: newSize.height)
              .shimmering()
          }
        }
      } else {
        AsyncImage(
              url: attachement.url,
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .cornerRadius(4)
              },
              placeholder: {
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color.gray)
                  .frame(height: imageMaxHeight)
                  .shimmering()
              })
      }
    case .gifv:
      VideoPlayerView(viewModel: .init(url: attachement.url))
        .frame(height: imageMaxHeight)
    case .none:
      EmptyView()
    }
  }
  
  @ViewBuilder
  private func makePreview(attachement: MediaAttachement) -> some View {
    if let type = attachement.supportedType {
      Group {
        GeometryReader { proxy in
          switch type {
          case .image:
            LazyImage(url: attachement.url) { state in
              if let image = state.image {
                image
                  .resizingMode(.aspectFill)
                  .cornerRadius(4)
              } else if state.isLoading {
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color.gray)
                  .frame(maxHeight: imageMaxHeight)
                  .frame(width: proxy.frame(in: .local).width)
                  .shimmering()
              }
            }
            .frame(width: proxy.frame(in: .local).width)
            .frame(height: imageMaxHeight)
          case .gifv:
            VideoPlayerView(viewModel: .init(url: attachement.url))
              .frame(width: proxy.frame(in: .local).width)
              .frame(height: imageMaxHeight)
          }
        }
        .frame(height: imageMaxHeight)
      }
      .onTapGesture {
        Task {
          await quickLook.prepareFor(urls: attachements.map{ $0.url }, selectedURL: attachement.url)
        }
      }
    }
  }
  
  private var quickLookLoadingView: some View {
    ZStack(alignment: .center) {
      VStack {
        Spacer()
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        Spacer()
      }
    }
    .background(.ultraThinMaterial)
  }
}
