import SwiftUI
import UIKit

struct StatusEditorCameraPickerView: UIViewControllerRepresentable {
  @Binding var selectedImage: UIImage?
  @Environment(\.dismiss) var dismiss

  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let picker: StatusEditorCameraPickerView

    init(picker: StatusEditorCameraPickerView) {
      self.picker = picker
    }

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      guard let selectedImage = info[.originalImage] as? UIImage else { return }
      picker.selectedImage = selectedImage
      picker.dismiss()
    }
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.delegate = context.coordinator
    return imagePicker
  }

  func updateUIViewController(_: UIImagePickerController, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(picker: self)
  }
}
