#if !os(visionOS)
  import DesignSystem
  import Env
  import Foundation
  import Photos
  import PhotosUI
  import SwiftUI
  import UIKit

  extension StatusEditor {
    @MainActor
    struct MediaPickerPanelView: View {
      @Environment(Theme.self) private var theme
      @Environment(CurrentInstance.self) private var currentInstance

      @Bindable var viewModel: ViewModel

      @State private var isPhotosPickerPresented: Bool = false
      @State private var isFileImporterPresented: Bool = false
      @State private var isCameraPickerPresented: Bool = false
      @State private var bottomCornerRadius: CGFloat = 16

      var body: some View {
        Group {
          if #available(iOS 26, *) {
            panelContent
              .buttonStyle(.glass)
              .font(.scaledFootnote)
              .glassEffect(.regular, in: panelContainerShape)
              .background(
                theme.primaryBackgroundColor.opacity(0.2), in: panelContainerShape
              )
              .clipShape(panelContainerShape)
              .padding(.horizontal, 16)
              .background {
                GeometryReader { proxy in
                  Color.clear
                    .onAppear {
                      updateBottomCornerRadius(proxy.safeAreaInsets.bottom)
                    }
                    .onChange(of: proxy.safeAreaInsets.bottom) { _, newValue in
                      updateBottomCornerRadius(newValue)
                    }
                }
              }
          } else {
            panelContent
              .buttonStyle(.bordered)
              .background(.ultraThickMaterial)
          }
        }
        .photosPicker(
          isPresented: $isPhotosPickerPresented,
          selection: $viewModel.mediaPickers,
          maxSelectionCount: currentInstance.instance?.configuration?.statuses.maxMediaAttachments
            ?? 4,
          matching: .any(of: [.images, .videos]),
          photoLibrary: .shared()
        )
        .fileImporter(
          isPresented: $isFileImporterPresented,
          allowedContentTypes: [.image, .video, .movie],
          allowsMultipleSelection: true
        ) { result in
          if let urls = try? result.get() {
            viewModel.processURLs(urls: urls)
          }
        }
        .fullScreenCover(
          isPresented: $isCameraPickerPresented,
          content: {
            CameraPickerView(
              selectedImage: .init(
                get: {
                  nil
                },
                set: { image in
                  if let image {
                    viewModel.processCameraPhoto(image: image)
                  }
                })
            )
            .background(.black)
          }
        )
      }

      private var panelContent: some View {
        VStack(spacing: 8) {
          RecentPhotosStripView { asset in
            await addAsset(asset)
          }

          HStack(spacing: 24) {
            Button {
              isPhotosPickerPresented = true
            } label: {
              Label("Library", systemImage: "photo")
            }

            #if !targetEnvironment(macCatalyst)
              Button {
                isCameraPickerPresented = true
              } label: {
                Label("Camera", systemImage: "camera")
              }
            #endif

            Button {
              isFileImporterPresented = true
            } label: {
              Label("Files", systemImage: "folder")
            }
            .accessibilityLabel("status.editor.browse-file")
          }
          .disabled(viewModel.showPoll)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
      }

      private var panelContainerShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
          topLeadingRadius: 16,
          bottomLeadingRadius: bottomCornerRadius,
          bottomTrailingRadius: bottomCornerRadius,
          topTrailingRadius: 16
        )
      }

      private func updateBottomCornerRadius(_ bottomInset: CGFloat) {
        let resolvedInset = max(bottomInset, resolvedBottomInset())
        let radius: CGFloat = resolvedInset > 0 ? 44 : 16
        if bottomCornerRadius != radius {
          bottomCornerRadius = radius
        }
      }

      private func resolvedBottomInset() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
      }

      private func addAsset(_ asset: PHAsset) async {
        guard asset.mediaType == .image else { return }

        let limit = currentInstance.instance?.configuration?.statuses.maxMediaAttachments ?? 4
        guard viewModel.mediaContainers.count < limit else { return }

        viewModel.isMediasLoading = true
        defer { viewModel.isMediasLoading = false }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none

        let dataResult = await withCheckedContinuation { continuation in
          PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
          ) { data, _, _, _ in
            continuation.resume(returning: data)
          }
        }

        if let dataResult {
          let tempURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).image")
          try? dataResult.write(to: tempURL)
          let compressor = Compressor()
          if let compressedData = await compressor.compressImageFrom(url: tempURL),
            let image = UIImage(data: compressedData)
          {
            viewModel.processCameraPhoto(image: image)
            return
          }
        }
      }
    }
  }

  @MainActor
  private struct RecentPhotosStripView: View {
    private let thumbnailSize: CGFloat = 150
    private let fetchLimit: Int = 20

    let onSelect: (PHAsset) async -> Void

    @State private var assets: [PHAsset] = []
    @State private var authorizationStatus: PHAuthorizationStatus =
      PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var body: some View {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 12) {
          if assets.isEmpty {
            ForEach(0..<6, id: \.self) { _ in
              RoundedRectangle(cornerRadius: 16)
                .fill(.secondary.opacity(0.2))
                .frame(width: thumbnailSize, height: thumbnailSize)
                .overlay {
                  ProgressView()
                }
            }
          } else {
            ForEach(assets, id: \.localIdentifier) { asset in
              PhotoAssetThumbnailView(
                asset: asset,
                size: thumbnailSize,
                onSelect: onSelect
              )
            }
          }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
      }
      .scrollIndicators(.hidden)
      .frame(height: thumbnailSize + 12)
      .task { await loadAssetsIfNeeded() }
    }

    private func loadAssetsIfNeeded() async {
      guard authorizationStatus == .notDetermined else {
        if authorizationStatus == .authorized || authorizationStatus == .limited {
          loadAssets()
        }
        return
      }

      var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      if status == .notDetermined {
        status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      }

      authorizationStatus = status
      if status == .authorized || status == .limited {
        loadAssets()
      }
    }

    private func loadAssets() {
      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      options.fetchLimit = fetchLimit

      let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
      var results: [PHAsset] = []
      results.reserveCapacity(fetchResult.count)
      fetchResult.enumerateObjects { asset, _, _ in
        results.append(asset)
      }

      assets = results
    }
  }

  @MainActor
  private struct PhotoAssetThumbnailView: View {
    let asset: PHAsset
    let size: CGFloat
    let onSelect: (PHAsset) async -> Void

    @State private var image: UIImage?

    var body: some View {
      Group {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          RoundedRectangle(cornerRadius: 16)
            .fill(.secondary.opacity(0.2))
            .overlay {
              Image(systemName: "photo")
                .foregroundStyle(.secondary)
            }
        }
      }
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .task {
        await loadThumbnailIfNeeded()
      }
      .onTapGesture {
        Task {
          await onSelect(asset)
        }
      }
    }

    private func loadThumbnailIfNeeded() async {
      guard image == nil else { return }

      let options = PHImageRequestOptions()
      options.resizeMode = .exact
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .highQualityFormat
      options.isSynchronous = false

      let scale = UIScreen.main.scale
      let targetSize = CGSize(width: size * scale, height: size * scale)

      let result = await withCheckedContinuation { continuation in
        var didResume = false
        PHImageManager.default().requestImage(
          for: asset,
          targetSize: targetSize,
          contentMode: .aspectFill,
          options: options
        ) { image, _ in
          guard !didResume else { return }
          didResume = true
          continuation.resume(returning: image)
        }
      }

      if let result {
        image = result
      }
    }
  }
#endif
