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

  func makeUIViewController(context _: Context) -> UIViewController {
    AppQLPreviewController(selectedURL: selectedURL, urls: urls)
  }

  func updateUIViewController(
    _: UIViewController, context _: Context
  ) {}
}

@MainActor
class AppQLPreviewController: UIViewController {
  let selectedURL: URL
  let urls: [URL]

  var qlController: QLPreviewController?

  init(selectedURL: URL, urls: [URL]) {
    self.selectedURL = selectedURL
    self.urls = urls
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if qlController == nil {
      qlController = QLPreviewController()
      qlController?.dataSource = self
      qlController?.delegate = self
      qlController?.currentPreviewItemIndex = urls.firstIndex(of: selectedURL) ?? 0
      present(qlController!, animated: true)
    }
  }
}

extension AppQLPreviewController: QLPreviewControllerDataSource {
  nonisolated func numberOfPreviewItems(in _: QLPreviewController) -> Int {
    urls.count
  }

  nonisolated func previewController(_: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    urls[index] as QLPreviewItem
  }
}

extension AppQLPreviewController: QLPreviewControllerDelegate {
  nonisolated func previewController(_: QLPreviewController, editingModeFor _: QLPreviewItem) -> QLPreviewItemEditingMode {
    .createCopy
  }

  nonisolated func previewControllerWillDismiss(_: QLPreviewController) {
    Task { @MainActor in
      dismiss(animated: true)
    }
  }

  nonisolated func previewControllerDidDismiss(_: QLPreviewController) {
    Task { @MainActor in
      dismiss(animated: true)
    }
  }
}

struct TransparentBackground: UIViewControllerRepresentable {
  public func makeUIViewController(context _: Context) -> UIViewController {
    TransparentController()
  }

  public func updateUIViewController(_: UIViewController, context _: Context) {}

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
