import SwiftUI
import Models
import Env
import Shimmer
import NukeUI
import DesignSystem

public struct StatusMediaPreviewView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var quickLook: QuickLook
  @EnvironmentObject private var theme: Theme
  
  public let attachements: [MediaAttachement]
  public let sensitive: Bool
  public let isNotifications: Bool

  @State private var isQuickLookLoading: Bool = false
  @State private var width: CGFloat = 0
  @State private var altTextDisplayed: String?
  @State private var isAltAlertDisplayed: Bool = false
  @State private var isHidingMedia: Bool = false
  
  private var imageMaxHeight: CGFloat {
    if isNotifications {
      return 50
    }
    if theme.statusDisplayStyle == .compact {
      return 100
    }
    if attachements.count == 1 {
      return 300
    }
    return attachements.count > 2 ? 100 : 200
  }
  
  private func size(for media: MediaAttachement) -> CGSize? {
    if isNotifications {
      return .init(width: 50, height: 50)
    }
    if theme.statusDisplayStyle == .compact {
      return .init(width: 100, height: 100)
    }
    if let width = media.meta?.original?.width,
       let height = media.meta?.original?.height {
      return .init(width: CGFloat(width), height: CGFloat(height))
    }
    return nil
  }
  
  private func imageSize(from: CGSize, newWidth: CGFloat) -> CGSize {
    if isNotifications {
      return .init(width: 50, height: 50)
    }
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
              await quickLook.prepareFor(urls: attachements.compactMap{ $0.url }, selectedURL: attachement.url!)
            }
          }
      } else {
        if isNotifications || theme.statusDisplayStyle == .compact {
          HStack {
            makeAttachementView(for: 0)
            makeAttachementView(for: 1)
            makeAttachementView(for: 2)
            makeAttachementView(for: 3)
          }
        } else {
          VStack {
            HStack {
              makeAttachementView(for: 0)
              makeAttachementView(for: 1)
            }
            HStack {
              makeAttachementView(for: 2)
              makeAttachementView(for: 3)
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
      
      if isHidingMedia {
        sensitiveMediaOverlay
          .transition(.opacity)
      }
    }
    .alert("Image description",
           isPresented: $isAltAlertDisplayed) {
      Button("Ok", action: { })
    } message: {
      Text(altTextDisplayed ?? "")
    }
    .onAppear {
      if sensitive && preferences.serverPreferences?.autoExpandmedia == .hideSensitive {
        isHidingMedia = true
      } else if preferences.serverPreferences?.autoExpandmedia == .hideAll {
        isHidingMedia = true
      } else {
        isHidingMedia = false
      }
    }

  }
  
  @ViewBuilder
  private func makeAttachementView(for index: Int) -> some View {
    if attachements.count > index {
      makePreview(attachement: attachements[index])
    }
  }
  
  @ViewBuilder
  private func makeFeaturedImagePreview(attachement: MediaAttachement) -> some View {
    switch attachement.supportedType {
    case .image:
      if theme.statusDisplayStyle == .large,
         let size = size(for: attachement),
         UIDevice.current.userInterfaceIdiom != .pad,
          UIDevice.current.userInterfaceIdiom != .mac {
        let avatarColumnWidth = theme.avatarPosition == .leading ? AvatarView.Size.status.size.width + .statusColumnsSpacing : 0
        let availableWidth = UIScreen.main.bounds.width - (.layoutPadding * 2) - avatarColumnWidth
        let newSize = imageSize(from: size,
                                newWidth: availableWidth)
        ZStack(alignment: .bottomTrailing) {
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
          if sensitive {
            cornerSensitiveButton
          }
          if let alt = attachement.description, !alt.isEmpty, !isNotifications {
            Button {
              altTextDisplayed = alt
              isAltAlertDisplayed = true
            } label: {
              Text("ALT")
            }
            .padding(8)
            .background(.thinMaterial)
            .cornerRadius(4)
          }
        }
      } else {
        AsyncImage(
              url: attachement.url,
              content: { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(maxHeight: imageMaxHeight)
                  .frame(maxWidth: imageMaxHeight)
                  .cornerRadius(4)
              },
              placeholder: {
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color.gray)
                  .frame(maxHeight: imageMaxHeight)
                  .frame(maxWidth: imageMaxHeight)
                  .shimmering()
              })
      }
    case .gifv, .video, .audio:
      if let url = attachement.url {
        VideoPlayerView(viewModel: .init(url: url))
          .frame(height: imageMaxHeight)
      }
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
            ZStack(alignment: .bottomTrailing) {
              LazyImage(url: attachement.url) { state in
                if let image = state.image {
                  image
                    .resizingMode(.aspectFill)
                    .cornerRadius(4)
                } else if state.isLoading {
                  RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(maxHeight: imageMaxHeight)
                    .frame(width: isNotifications ? imageMaxHeight : proxy.frame(in: .local).width)
                    .shimmering()
                }
              }
              .frame(width: isNotifications ? imageMaxHeight : proxy.frame(in: .local).width)
              .frame(height: imageMaxHeight)
              if sensitive {
                cornerSensitiveButton
              }
              if let alt = attachement.description, !alt.isEmpty, !isNotifications {
                Button {
                  altTextDisplayed = alt
                  isAltAlertDisplayed = true
                } label: {
                  Text("ALT")
                    .font(.footnote)
                }
                .padding(4)
                .background(.thinMaterial)
                .cornerRadius(4)
              }
            }
          case .gifv, .video, .audio:
            if let url = attachement.url {
              VideoPlayerView(viewModel: .init(url: url))
                .frame(width: isNotifications ? imageMaxHeight :  proxy.frame(in: .local).width)
                .frame(height: imageMaxHeight)
            }
          }
        }
        .frame(width: isNotifications ? imageMaxHeight : nil)
        .frame(height: imageMaxHeight)
      }
      .onTapGesture {
        Task {
          await quickLook.prepareFor(urls: attachements.compactMap{ $0.url }, selectedURL: attachement.url!)
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
  
  private var sensitiveMediaOverlay: some View {
    Rectangle()
      .background(.ultraThinMaterial)
      .overlay {
        if !isNotifications {
          Button {
            withAnimation {
              isHidingMedia = false
            }
          } label: {
            if sensitive {
              Label("Show sensitive content", systemImage: "eye")
            } else {
              Label("Show content", systemImage: "eye")
            }
          }
          .buttonStyle(.borderedProminent)
        }
      }
  }
  
  private var cornerSensitiveButton: some View {
    Button {
      withAnimation {
        isHidingMedia = true
      }
    } label: {
      Image(systemName:"eye.slash")
    }
    .position(x: 30, y: 30)
    .buttonStyle(.borderedProminent)
  }
}
