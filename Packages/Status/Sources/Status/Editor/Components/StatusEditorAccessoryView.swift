import SwiftUI
import DesignSystem
import PhotosUI
import Models
import Env

struct StatusEditorAccessoryView: View {
  @EnvironmentObject private var currentInstance: CurrentInstance
  
  @FocusState<Bool>.Binding var isSpoilerTextFocused: Bool
  @ObservedObject var viewModel: StatusEditorViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      Divider()
      HStack(alignment: .center, spacing: 16) {
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
        
        Button {
          withAnimation {
            viewModel.spoilerOn.toggle()
          }
          isSpoilerTextFocused.toggle()
        } label: {
          Image(systemName: viewModel.spoilerOn ? "exclamationmark.triangle.fill": "exclamationmark.triangle")
        }

        visibilityMenu

        Spacer()
        
        characterCountView
      }
      .frame(height: 20)
      .padding(.horizontal, .layoutPadding)
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
      Section("Post visibility") {
        ForEach(Models.Visibility.allCases, id: \.self) { visibility in
          Button {
            viewModel.visibility = visibility
          } label: {
            Label(visibility.title, systemImage: visibility.iconName)
          }
        }
      }
    } label: {
      Image(systemName: viewModel.visibility.iconName)
    }
  }
}
