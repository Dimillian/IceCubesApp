import Foundation
import Testing

@testable import Models

private let collectionJSON = """
  {
    "id": "116131056935959117",
    "account_id": "113668893442515793",
    "uri": "https://example.com/ap/113668893442515793/collections/116131056935959117",
    "url": "https://example.com/collections/116131056935959117",
    "name": "Excellent people",
    "description": "Well worth following",
    "language": "en",
    "local": true,
    "sensitive": false,
    "discoverable": true,
    "tag": null,
    "item_count": 1,
    "items": [
      {
        "id": "116141056635954112",
        "account_id": "112658193342215767",
        "state": "accepted",
        "created_at": "2026-02-25T11:35:01.394Z"
      }
    ],
    "created_at": "2026-02-25T11:35:01.394Z",
    "updated_at": "2026-02-25T11:37:38.182Z"
  }
  """

private let accountJSON = """
  {
    "id": "113668893442515793",
    "username": "curator",
    "acct": "curator@example.com",
    "display_name": "Curator",
    "note": "",
    "avatar": "https://example.com/avatar.png",
    "header": "https://example.com/header.png",
    "locked": false,
    "emojis": [],
    "fields": [],
    "created_at": "2026-01-01T00:00:00.000Z",
    "followers_count": 0,
    "following_count": 0,
    "statuses_count": 0,
    "bot": false,
    "discoverable": true
  }
  """

private func makeDecoder() -> JSONDecoder {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}

@Test
func testAddedToCollectionNotificationDecoding() throws {
  let json = """
    {
      "id": "34975861",
      "type": "added_to_collection",
      "created_at": "2026-06-10T09:42:00.000Z",
      "group_key": "ungrouped-34975861",
      "account": \(accountJSON),
      "collection": \(collectionJSON)
    }
    """

  let notification = try makeDecoder().decode(
    Models.Notification.self, from: Data(json.utf8))

  #expect(notification.supportedType == .added_to_collection)
  #expect(notification.status == nil)
  #expect(notification.collection?.id == "116131056935959117")
  #expect(notification.collection?.name == "Excellent people")
  #expect(notification.collection?.acceptedAccountIds == ["112658193342215767"])
}

@Test
func testCollectionUpdateNotificationDecoding() throws {
  let json = """
    {
      "id": "34975862",
      "type": "collection_update",
      "created_at": "2026-06-10T09:43:00.000Z",
      "group_key": "ungrouped-34975862",
      "account": \(accountJSON),
      "collection": \(collectionJSON)
    }
    """

  let notification = try makeDecoder().decode(
    Models.Notification.self, from: Data(json.utf8))

  #expect(notification.supportedType == .collection_update)
  #expect(notification.collection?.itemCount == 1)
}

@Test
func testNotificationWithoutCollectionStillDecodes() throws {
  let json = """
    {
      "id": "34975863",
      "type": "follow",
      "created_at": "2026-06-10T09:44:00.000Z",
      "group_key": "ungrouped-34975863",
      "account": \(accountJSON)
    }
    """

  let notification = try makeDecoder().decode(
    Models.Notification.self, from: Data(json.utf8))

  #expect(notification.supportedType == .follow)
  #expect(notification.collection == nil)
}

@Test
func testNotificationGroupDecodesCollection() throws {
  let json = """
    {
      "group_key": "added_to_collection-116131056935959117",
      "notifications_count": 1,
      "type": "added_to_collection",
      "most_recent_notification_id": 34975861,
      "page_min_id": "34975861",
      "page_max_id": "34975861",
      "latest_page_notification_at": "2026-06-10T09:42:00.000Z",
      "sample_account_ids": ["113668893442515793"],
      "collection": \(collectionJSON)
    }
    """

  let group = try makeDecoder().decode(NotificationGroup.self, from: Data(json.utf8))

  #expect(group.type == "added_to_collection")
  #expect(group.statusId == nil)
  #expect(group.collection?.name == "Excellent people")
}
