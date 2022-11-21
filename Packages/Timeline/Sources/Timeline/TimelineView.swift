import SwiftUI
import Network

public struct TimelineView: View {
  public enum Kind {
    case pub, hastah, home, list
  }
  
  @EnvironmentObject private var client: Client
  
  @State private var statuses: [Status] = []
  
  private let kind: Kind
  
  public init(kind: Kind) {
    self.kind = kind
  }
  
  public var body: some View {
    List(statuses) { status in
      StatusRowView(status: status)
    }
    .task {
      do {
        self.statuses = try await client.fetchArray(endpoint: Timeline.pub)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}
