import Foundation
import Models
import SwiftData
import XCTest

@testable import Account

@MainActor
final class AccountMetricsStoreTests: XCTestCase {
  func testUpsertInsertsNewGroups() throws {
    let context = try makeContext()
    let store = AccountMetricsStore()
    let accountId = "account-1"
    let server = "example.com"

    let firstDate = makeDate("2026-01-05T10:00:00.000Z")
    let secondDate = makeDate("2026-01-06T12:00:00.000Z")

    let firstGroup = try makeNotificationGroup(
      groupKey: "group-1",
      type: "follow",
      count: 2,
      mostRecentId: 10,
      date: firstDate
    )
    let secondGroup = try makeNotificationGroup(
      groupKey: "group-2",
      type: "reblog",
      count: 5,
      mostRecentId: 12,
      date: secondDate
    )

    store.upsert(
      groups: [firstGroup, secondGroup],
      accountId: accountId,
      server: server,
      modelContext: context
    )

    let saved = try context.fetch(FetchDescriptor<MetricsNotificationGroup>())
    XCTAssertEqual(saved.count, 2)

    let storedKeys = Set(saved.map(\.groupKey))
    XCTAssertEqual(
      storedKeys,
      ["\(server)|\(accountId)|group-1", "\(server)|\(accountId)|group-2"]
    )
  }

  func testUpsertUpdatesExistingGroup() throws {
    let context = try makeContext()
    let calendar = makeCalendar()
    let store = AccountMetricsStore()
    let accountId = "account-1"
    let server = "example.com"

    let firstDate = makeDate("2026-01-05T10:00:00.000Z")
    let secondDate = makeDate("2026-01-06T12:00:00.000Z")

    let initialGroup = try makeNotificationGroup(
      groupKey: "group-1",
      type: "follow",
      count: 1,
      mostRecentId: 10,
      date: firstDate
    )
    let updatedGroup = try makeNotificationGroup(
      groupKey: "group-1",
      type: "follow",
      count: 4,
      mostRecentId: 15,
      date: secondDate
    )

    store.upsert(
      groups: [initialGroup],
      accountId: accountId,
      server: server,
      modelContext: context
    )
    store.upsert(
      groups: [updatedGroup],
      accountId: accountId,
      server: server,
      modelContext: context
    )

    let stored = try context.fetch(FetchDescriptor<MetricsNotificationGroup>())
    XCTAssertEqual(stored.count, 1)

    let saved = stored[0]
    XCTAssertEqual(saved.notificationsCount, 4)
    XCTAssertEqual(saved.mostRecentNotificationId, 15)
    XCTAssertEqual(saved.latestPageNotificationAt, secondDate)
    XCTAssertEqual(saved.dayStart, calendar.startOfDay(for: secondDate))
  }

  func testPruneOldGroupsRemovesEntriesBeforeRetention() throws {
    let context = try makeContext()
    let calendar = makeCalendar()
    let store = AccountMetricsStore()
    let accountId = "account-1"
    let server = "example.com"

    let now = Date()
    let recentDate = calendar.date(byAdding: .day, value: -10, to: now) ?? now
    let oldDate = calendar.date(byAdding: .day, value: -100, to: now) ?? now

    let recentGroup = try makeNotificationGroup(
      groupKey: "recent",
      type: "follow",
      count: 1,
      mostRecentId: 12,
      date: recentDate
    )
    let oldGroup = try makeNotificationGroup(
      groupKey: "old",
      type: "follow",
      count: 1,
      mostRecentId: 10,
      date: oldDate
    )

    store.upsert(
      groups: [recentGroup, oldGroup],
      accountId: accountId,
      server: server,
      modelContext: context
    )

    store.pruneOldGroups(
      accountId: accountId,
      server: server,
      keepingDays: 90,
      modelContext: context
    )

    let saved = try context.fetch(FetchDescriptor<MetricsNotificationGroup>())
    XCTAssertEqual(saved.count, 1)
    XCTAssertEqual(saved.first?.groupKey, "\(server)|\(accountId)|recent")
  }

  private func makeContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: MetricsNotificationGroup.self,
      configurations: config
    )
    return ModelContext(container)
  }

  private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
    return calendar
  }

  private func makeDate(_ value: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = .init(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.date(from: value) ?? Date.distantPast
  }

  private func makeNotificationGroup(
    groupKey: String,
    type: String,
    count: Int,
    mostRecentId: Int,
    date: Date
  ) throws -> NotificationGroup {
    let formatter = DateFormatter()
    formatter.calendar = .init(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    let json: [String: Any] = [
      "group_key": groupKey,
      "notifications_count": count,
      "type": type,
      "most_recent_notification_id": mostRecentId,
      "page_min_id": NSNull(),
      "page_max_id": NSNull(),
      "latest_page_notification_at": formatter.string(from: date),
      "sample_account_ids": [],
      "status_id": NSNull(),
    ]

    let data = try JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(NotificationGroup.self, from: data)
  }
}
