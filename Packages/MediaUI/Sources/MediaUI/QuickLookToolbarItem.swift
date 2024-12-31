import Nuke
import NukeUI
import SwiftUI

struct QuickLookToolbarItem: ToolbarContent, @unchecked Sendable {
  let itemUrl: URL
  @State private var localPath: URL?
  @State private var isLoading = false

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        Task {
          isLoading = true
          localPath = await localPathFor(url: itemUrl)
          isLoading = false
        }
      } label: {
        if isLoading {
          ProgressView()
        } else {
          Image(systemName: "info.circle")
        }
      }
      .quickLookPreview($localPath)
    }
  }

  private func imageData(_ url: URL) async -> Data? {
    var data = ImagePipeline.shared.cache.cachedData(for: .init(url: url))
    if data == nil {
      data = try? await URLSession.shared.data(from: url).0
    }
    return data
  }

  private func localPathFor(url: URL) async -> URL {
    try? FileManager.default.removeItem(at: quickLookDir)
    try? FileManager.default.createDirectory(at: quickLookDir, withIntermediateDirectories: true)
    let path = quickLookDir.appendingPathComponent(url.lastPathComponent)
    let data = await imageData(url)
    try? data?.write(to: path)
    return path
  }

  private var quickLookDir: URL {
    try! FileManager.default.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
    .appending(component: "quicklook")
  }
}
