//
//  RSSUITextView.swift
//  IceCubesApp
//
//  Created by Duong Thai on 28/02/2024.
//

import SwiftUI
import DesignSystem

@MainActor
struct RSSItemDetailView: UIViewControllerRepresentable {
  let content: NSAttributedString

  func makeUIViewController(context: Context) -> RSSUITextViewController {
    RSSUITextViewController(content)
  }

  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

class RSSUITextViewController: UIViewController {
  private var imageCache: [(attachment: NSTextAttachment, originalSize: CGSize)]?
  private let textView: UITextView

  init(_ content: NSAttributedString) {
    let padding: CGFloat = 20
    let textView = UITextView()

    textView.isEditable = false
    textView.textContainer.lineBreakMode = .byWordWrapping
    textView.textContainer.widthTracksTextView = true
    textView.textContainerInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)

    textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    textView.isEditable = false
    textView.attributedText = content

    self.textView = textView

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view = textView
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    resizeImage()
  }

  private func calculateDisplaySize(from originalSize: CGSize) -> CGSize {
    let viewWidth = self.textView.frame.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right
    let viewHeight = self.textView.frame.height
    guard viewWidth > 0, viewHeight > 0 else { return originalSize }

    return if originalSize.width == 0 {
      CGSize.zero
    } else if originalSize.width < 100 {
      // TODO: some authors use small use images to display special characters
      // still don't know how to deal with it
      originalSize
    } else {
      CGSize(
        width: viewWidth,
        height: originalSize.height * viewWidth / originalSize.width
      )
    }
  }

  private func resizeImage() {
    if let imageCache {
      for cache in imageCache {
        let size = calculateDisplaySize(from: cache.originalSize)
        cache.attachment.bounds = CGRect(origin: cache.attachment.bounds.origin, size: size)
      }
    } else {
      imageCache = []

      self.textView.attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.textView.attributedText.length)) { value, _, _ in
        if let attachment = value as? NSTextAttachment,
           let data = attachment.fileWrapper?.regularFileContents,
           let image = UIImage(data: data)
        {
          let size = calculateDisplaySize(from: image.size)
          imageCache?.append((attachment, size))
          attachment.bounds = CGRect(origin: attachment.bounds.origin, size: size)
        }
      }
    }
  }
}

#Preview {
  RSSItemDetailView(content: RSSExampleData.content)
    .environment(Theme.shared)
}
