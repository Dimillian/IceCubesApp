import UIKit
import SwiftUI
import QuickLook

extension URL: Identifiable {
  public var id: String {
    absoluteString
  }
}

struct QuickLookPreview: UIViewControllerRepresentable {
  let selectedURL: URL
  let urls: [URL]
  
  func makeUIViewController(context: Context) -> UINavigationController {
    let controller = AppQLPreviewController()
    controller.dataSource = context.coordinator
    controller.delegate = context.coordinator
    let nav = UINavigationController(rootViewController: controller)
    return nav
  }
  
  func updateUIViewController(
    _ uiViewController: UINavigationController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }
  
  class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    let parent: QuickLookPreview
    
    init(parent: QuickLookPreview) {
      self.parent = parent
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
      return parent.urls.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      return parent.urls[index] as QLPreviewItem
    }
    
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
      .createCopy
    }
  }
}

class AppQLPreviewController: QLPreviewController {
  private var closeButton: UIBarButtonItem {
    .init(title: "Done", style: .plain, target: self, action: #selector(onCloseButton))
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = closeButton
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigationItem.rightBarButtonItem = closeButton
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    navigationItem.rightBarButtonItem = closeButton
  }
  
  @objc private func onCloseButton() {
    dismiss(animated: true)
  }
}
