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

  func makeUIViewController(context: Context) -> UIViewController {
    return AppQLPreviewController(selectedURL: selectedURL, urls: urls)
  }

  func updateUIViewController(
    _: UIViewController, context _: Context
  ) {}
}

class AppQLPreviewController: UIViewController {
  let selectedURL: URL
  let urls: [URL]
  
  var qlController : QLPreviewController?
  
  init(selectedURL: URL, urls: [URL]) {
    self.selectedURL = selectedURL
    self.urls = urls
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.qlController == nil {
      self.qlController = QLPreviewController()
      self.qlController?.dataSource = self
      self.qlController?.delegate = self
      self.qlController?.currentPreviewItemIndex = urls.firstIndex(of: selectedURL) ?? 0
      self.present(self.qlController!, animated: true)
    }
  }
}

extension AppQLPreviewController : QLPreviewControllerDataSource {
  func numberOfPreviewItems(in _: QLPreviewController) -> Int {
    return self.urls.count
  }

  func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return self.urls[index] as QLPreviewItem
  }
}

extension AppQLPreviewController : QLPreviewControllerDelegate {
  func previewController(_: QLPreviewController, editingModeFor _: QLPreviewItem) -> QLPreviewItemEditingMode {
    .createCopy
  }

  func previewControllerWillDismiss(_ controller: QLPreviewController) {
    self.dismiss(animated: true)
  }
}

struct TransparentBackground: UIViewControllerRepresentable {
  public func makeUIViewController(context: Context) -> UIViewController {
    return TransparentController()
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
  }
  
  class TransparentController: UIViewController {
    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .clear
    }
    
    override func willMove(toParent parent: UIViewController?) {
      super.willMove(toParent: parent)
      parent?.view?.backgroundColor = .clear
      parent?.modalPresentationStyle = .overCurrentContext
    }
  }
}
