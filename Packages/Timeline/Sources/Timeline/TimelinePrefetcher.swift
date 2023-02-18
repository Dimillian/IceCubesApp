import SwiftUI
import UIKit
import Models
import Nuke

final class TimelinePrefetcher: NSObject, ObservableObject, UICollectionViewDataSourcePrefetching {
  private let prefetcher = ImagePrefetcher()

  weak var viewModel: TimelineViewModel?

  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    let imageURLs = getImageURLs(for: indexPaths)
    prefetcher.startPrefetching(with: imageURLs)
  }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    let imageURLs = getImageURLs(for: indexPaths)
    prefetcher.stopPrefetching(with: imageURLs)
  }

  private func getImageURLs(for indexPaths: [IndexPath]) -> [URL] {
    guard let viewModel, case .display(let statuses, _) = viewModel.statusesState else {
      return []
    }
    return indexPaths.compactMap {
      $0.row < statuses.endIndex ? statuses[$0.row] : nil
    }.flatMap(getImages)
  }
}

private func getImages(for status: Status) -> [URL] {
  status.mediaAttachments.compactMap {
    if $0.supportedType == .image {
      return status.mediaAttachments.count > 1 ? $0.previewUrl ?? $0.url : $0.url
    }
    return nil
  }
}
