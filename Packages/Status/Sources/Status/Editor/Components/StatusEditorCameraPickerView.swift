import UIKit
import SwiftUI

struct StatusEditorCameraPickerView: UIViewControllerRepresentable {
  @Binding var selectedImage: UIImage?
  @Environment(\.presentationMode) var isPresented
  
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let picker: StatusEditorCameraPickerView
    
    init(picker: StatusEditorCameraPickerView) {
      self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      guard let selectedImage = info[.originalImage] as? UIImage else { return }
      self.picker.selectedImage = selectedImage
      self.picker.isPresented.wrappedValue.dismiss()
    }
  }
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.delegate = context.coordinator
    return imagePicker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(picker: self)
  }
}
