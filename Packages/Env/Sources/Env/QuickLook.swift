import Combine
@preconcurrency import SwiftUI
import Models
import QuickLook

@MainActor
@Observable public class QuickLook {
  public var selectedMediaAttachment: MediaAttachment?
  public var mediaAttachments: [MediaAttachment] = []
  
  public var url: URL? {
    didSet {
      if url == nil {
        cleanup(urls: urls)
      }
    }
  }
  public private(set) var urls: [URL] = []
  
  
  public init() {}
  
  public func prepareFor(selectedMediaAttachment: MediaAttachment, mediaAttachments: [MediaAttachment]) {
    if ProcessInfo.processInfo.isiOSAppOnMac, let selectedURL = selectedMediaAttachment.url {
      let urls = mediaAttachments.compactMap{ $0.url }
      Task {
        await prepareFor(urls: urls, selectedURL: selectedURL)
      }
    } else {
      self.selectedMediaAttachment = selectedMediaAttachment
      self.mediaAttachments = mediaAttachments
    }
  }
  
  private func prepareFor(urls: [URL], selectedURL: URL) async {
    var transaction = Transaction(animation: .default)
    transaction.disablesAnimations = true
    do {
      var order = 0
      let pathOrderMap = urls.reduce(into: [String: Int]()) { result, url in
        result[url.lastPathComponent] = order
        order += 1
      }
      let paths: [URL] = try await withThrowingTaskGroup(of: URL.self, body: { group in
        var paths: [URL] = []
        for url in urls {
          group.addTask {
            try await self.localPathFor(url: url)
          }
        }
        for try await path in group {
          paths.append(path)
        }
        return paths.sorted { url1, url2 in
          pathOrderMap[url1.lastPathComponent] ?? 0 < pathOrderMap[url2.lastPathComponent] ?? 0
        }
      })
      withTransaction(transaction) {
        self.urls = paths
        url = paths.first(where: { $0.lastPathComponent == selectedURL.lastPathComponent })
      }
    } catch {
      withTransaction(transaction) {
        self.urls = []
        url = nil
      }
    }
  }
  
  private var quickLookDir: URL {
    try! FileManager.default.url(for: .cachesDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: false)
    .appending(component: "quicklook")
  }
  
  private func localPathFor(url: URL) async throws -> URL {
    try? FileManager.default.createDirectory(at: quickLookDir, withIntermediateDirectories: true)
    let path = quickLookDir.appendingPathComponent(url.lastPathComponent)
    
    // Warning: Non-sendable type '(any URLSessionTaskDelegate)?' exiting main actor-isolated
    // context in call to non-isolated instance method 'data(for:delegate:)' cannot cross actor
    // boundary.
    // This is on the defaulted-to-nil second parameter of `.data(from:delegate:)`.
    // There is a Radar tracking this & others like it.
    let data = try await URLSession.shared.data(from: url).0
    try data.write(to: path)
    return path
  }
  
  private func cleanup(urls _: [URL]) {
    try? FileManager.default.removeItem(at: quickLookDir)
  }
}
