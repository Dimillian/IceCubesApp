import DesignSystem
import Env
import NetworkClient
import SwiftUI

struct StatusRowShareAsImageView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme

  let viewModel: StatusRowViewModel
  @StateObject var renderer: ImageRenderer<AnyView>

  var rendererImage: Image {
    Image(uiImage: renderer.uiImage ?? UIImage())
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Button {
            viewModel.routerPath.presentedSheet = .shareImage(
              image: renderer.uiImage ?? UIImage(),
              status: viewModel.status)
          } label: {
            Label("status.action.share-image", systemImage: "square.and.arrow.up")
          }
        }
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor.opacity(0.4))
        #endif

        Section {
          rendererImage
            .resizable()
            .scaledToFit()
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text("action.done")
              .bold()
          }
        }
      }
      .navigationTitle("Share post as image")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationBackground(.ultraThinMaterial)
    .presentationCornerRadius(16)
  }
}
