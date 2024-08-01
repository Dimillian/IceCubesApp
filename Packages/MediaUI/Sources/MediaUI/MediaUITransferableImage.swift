import CoreTransferable
import SwiftUI
import UIKit

public struct MediaUIImageTransferable: Codable, Transferable {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func fetchData() async -> Data {
    do {
      return try await URLSession.shared.data(from: url).0
    } catch {
      return Data()
    }
  }

  public static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .jpeg) { transferable in
      await transferable.fetchData()
    }
  }
}
