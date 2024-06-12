import Models
import Network
import Testing
import Foundation
@testable import Timeline

@Test
func testTimelineCodableHome() {
  #expect(testCodableOn(filter: .home))
  #expect(testCodableOn(filter: .local))
  #expect(testCodableOn(filter: .federated))
  #expect(testCodableOn(filter: .remoteLocal(server: "me.dm", filter: .local)))
  #expect(testCodableOn(filter: .tagGroup(title: "test", tags: ["test"], symbolName: nil)))
  #expect(testCodableOn(filter: .tagGroup(title: "test", tags: ["test"], symbolName: "test")))
  #expect(testCodableOn(filter: .hashtag(tag: "test", accountId: nil)))
  #expect(testCodableOn(filter: .list(list: .init(id: "test", title: "test"))))
}

fileprivate func testCodableOn(filter: TimelineFilter) -> Bool {
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  guard let data = try? encoder.encode(filter) else {
    return false
  }
  let newFilter = try? decoder.decode(TimelineFilter.self, from: data)
  return newFilter == filter

}
