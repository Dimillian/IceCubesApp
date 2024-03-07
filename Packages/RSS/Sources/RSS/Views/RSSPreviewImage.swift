//
//  RSSPreviewImage.swift
//  IceCubesApp
//
//  Created by Duong Thai on 02/03/2024.
//

import SwiftUI
import NukeUI

struct RSSPreviewImage: View, Sendable {
  private let url: URL
  private let originalSize: CGSize

  init(url: URL, originalSize: CGSize) {
    self.url = url
    self.originalSize = originalSize
  }

  public var body: some View {
    _Layout(originalWidth: originalSize.width, originalHeight: originalSize.height) {
      Rectangle()
        .overlay {
          LazyImage(url: url) { state in
            if let image = state.image {
              image.resizable().scaledToFill()
            }
          }
        }
        .cornerRadius(10)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(.gray.opacity(0.35), lineWidth: 1)
        }
    }
  }

  private struct _Layout: Layout {
    let originalWidth: CGFloat
    let originalHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
      guard !subviews.isEmpty else { return CGSize.zero }
      return calculateSize(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
      guard let view = subviews.first else { return }

      let size = calculateSize(proposal)
      view.place(at: bounds.origin, proposal: ProposedViewSize(size))
    }

    private func calculateSize(_ proposal: ProposedViewSize) -> CGSize {
      var size = switch (proposal.width, proposal.height) {
      case (nil, nil):
        CGSize(width: originalWidth, height: originalWidth)
      case let (nil, .some(height)):
        CGSize(width: originalWidth, height: min(height, originalWidth))
      case (0, _):
        CGSize.zero
      case let (.some(width), _):
        if originalWidth == 0 {
          CGSize(width: width, height: width / 2)
        } else {
          CGSize(width: width, height: width / originalWidth * originalHeight)
        }
      }

      size.height = min(size.height, 450)
      return size
    }
  }
}
