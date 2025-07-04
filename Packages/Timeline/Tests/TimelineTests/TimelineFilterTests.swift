import Foundation
import Models
import NetworkClient
import Testing

@testable import Timeline

@Suite("Timeline Filter Tests")
struct TimelineFilterTests {
  @Test(
    "All timeline filter can be decoded and encoded",
    arguments: [
      TimelineFilter.home,
      TimelineFilter.local,
      TimelineFilter.federated,
      TimelineFilter.remoteLocal(server: "me.dm", filter: .local),
      TimelineFilter.tagGroup(title: "test", tags: ["test"], symbolName: nil),
      TimelineFilter.tagGroup(title: "test", tags: ["test"], symbolName: "test"),
      TimelineFilter.hashtag(tag: "test", accountId: nil),
    ])
  func timelineCanEncodeAndDecode(filter: TimelineFilter) {
    #expect(testCodableOn(filter: filter))
  }

  func testCodableOn(filter: TimelineFilter) -> Bool {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    guard let data = try? encoder.encode(filter) else {
      return false
    }
    let newFilter = try? decoder.decode(TimelineFilter.self, from: data)
    return newFilter == filter

  }

}
