import QuickLook
import SwiftUI
import UIKit

extension URL: Identifiable {
  public var id: String {
    absoluteString
  }
}

struct QuickLookPreview: UIViewControllerRepresentable {
  let selectedURL: URL
  let urls: [URL]

  func makeUIViewController(context: Context) -> UINavigationController {
    let controller = AppQLPreviewCpntroller()
    controller.dataSource = context.coordinator
    controller.delegate = context.coordinator
    let nav = UINavigationController(rootViewController: controller)
    return nav
  }

  func updateUIViewController(
    _: UINavigationController, context _: Context
  ) {}

  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }

  class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    let parent: QuickLookPreview

    init(parent: QuickLookPreview) {
      self.parent = parent
    }

    func numberOfPreviewItems(in _: QLPreviewController) -> Int {
      return parent.urls.count
    }

    func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
      return parent.urls[index] as QLPreviewItem
    }

    func previewController(_: QLPreviewController, editingModeFor _: QLPreviewItem) -> QLPreviewItemEditingMode {
      .createCopy
    }
  }
}

class AppQLPreviewCpntroller: QLPreviewController {
  private var closeButton: UIBarButtonItem {
    .init(title: "Done", style: .plain, target: self, action: #selector(onCloseButton))
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if UIDevice.current.userInterfaceIdiom != .pad {
      navigationItem.rightBarButtonItem = closeButton
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    navigationItem.rightBarButtonItem = closeButton
  }

  @objc private func onCloseButton() {
    dismiss(animated: true)
  }
}
