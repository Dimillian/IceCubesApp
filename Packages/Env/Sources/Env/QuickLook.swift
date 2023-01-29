import QuickLook
import SwiftUI

@MainActor
public class QuickLook: ObservableObject {
  @Published public var url: URL?
  @Published public private(set) var urls: [URL] = []
  @Published public private(set) var isPreparing: Bool = false
  @Published public private(set) var latestError: Error?

  public init() {}

  public func prepareFor(urls: [URL], selectedURL: URL) async {
    var transaction = Transaction(animation: .default)
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      isPreparing = true
    }
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
          return pathOrderMap[url1.lastPathComponent] ?? 0 < pathOrderMap[url2.lastPathComponent] ?? 0
        }
      })
      withTransaction(transaction) {
        self.urls = paths
        url = paths.first(where: { $0.lastPathComponent == selectedURL.lastPathComponent })
        isPreparing = false
      }
    } catch {
      withTransaction(transaction) {
        isPreparing = false
        self.urls = []
        url = nil
        latestError = error
      }
    }
  }

  private func localPathFor(url: URL) async throws -> URL {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
    let path = tempDir.appendingPathComponent(url.lastPathComponent)
    let data = try await URLSession.shared.data(from: url).0
    try data.write(to: path)
    return path
  }
}
