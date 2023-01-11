import SwiftUI
import DesignSystem
import PhotosUI
import Models
import Env

struct StatusEditorAccessoryView: View {
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentInstance: CurrentInstance
  
  @FocusState<Bool>.Binding var isSpoilerTextFocused: Bool
  @ObservedObject var viewModel: StatusEditorViewModel
  @State private var isDrafsSheetDisplayed: Bool = false
  
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
        
        Button {
          isDrafsSheetDisplayed = true
        } label: {
          Image(systemName: "archivebox")
        }


        Spacer()
        
        characterCountView
      }
      .frame(height: 20)
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial)
    }
    .sheet(isPresented: $isDrafsSheetDisplayed) {
      draftsSheetView
    }
  }
  
  private var draftsSheetView: some View {
    NavigationStack {
      List {
        ForEach(preferences.draftsPosts, id: \.self) { draft in
          Text(draft)
            .lineLimit(3)
            .listRowBackground(theme.primaryBackgroundColor)
            .onTapGesture {
              viewModel.insertStatusText(text: draft)
              isDrafsSheetDisplayed = false
            }
        }
        .onDelete { indexes in
          if let index = indexes.first {
            preferences.draftsPosts.remove(at: index)
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { dismiss() })
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("Drafts")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium])
  }
  
  
  private var characterCountView: some View {
    Text("\((currentInstance.instance?.configuration.statuses.maxCharacters ?? 500) - viewModel.statusText.string.utf16.count)")
      .foregroundColor(.gray)
      .font(.callout)
  }
}
