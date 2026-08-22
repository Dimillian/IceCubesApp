import Foundation
import Testing

@testable import Models

@Test
func testAccountCollectionDecoding() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  // Example payload from https://docs.joinmastodon.org/entities/Collection/
  let json = """
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
      "tag": {
        "name": "discovery",
        "url": "https://example.com/tags/discovery"
      },
      "item_count": 2,
      "items": [
        {
          "id": "116141056635954112",
          "account_id": "112658193342215767",
          "state": "accepted",
          "created_at": "2026-02-25T11:35:01.394Z"
        },
        {
          "id": "116141051635254139",
          "account_id": "117628196343117789",
          "state": "pending",
          "created_at": "2026-02-25T11:35:01.394Z"
        }
      ],
      "created_at": "2026-02-25T11:35:01.394Z",
      "updated_at": "2026-02-25T11:37:38.182Z"
    }
    """

  let collection = try decoder.decode(AccountCollection.self, from: Data(json.utf8))
  #expect(collection.id == "116131056935959117")
  #expect(collection.accountId == "113668893442515793")
  #expect(collection.name == "Excellent people")
  #expect(collection.description.asRawText == "Well worth following")
  #expect(collection.language == "en")
  #expect(collection.local == true)
  #expect(collection.sensitive == false)
  #expect(collection.discoverable == true)
  #expect(collection.tag?.name == "discovery")
  #expect(collection.itemCount == 2)
  #expect(collection.items.count == 2)
  #expect(collection.items[0].state == "accepted")
  #expect(collection.items[1].state == "pending")
  #expect(collection.acceptedAccountIds == ["112658193342215767"])
}

@Test
func testAccountCollectionsResponseDecoding() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  // GET /api/v1/accounts/:id/collections wraps the array (shape observed on
  // mastodon.social 4.6).
  let json = """
    {
      "collections": [
        {
          "id": "116784146949292427",
          "uri": "https://mastodon.social/ap/users/1/collections/116784146949292427",
          "name": "News organizations of Mastodon",
          "description": "",
          "language": "en",
          "account_id": "1",
          "local": true,
          "sensitive": false,
          "discoverable": true,
          "url": "https://mastodon.social/collections/116784146949292427",
          "item_count": 6,
          "created_at": "2026-06-20T19:44:24.162Z",
          "updated_at": "2026-06-20T19:44:24.162Z",
          "tag": {
            "name": "news",
            "url": "https://mastodon.social/tags/news"
          },
          "items": []
        }
      ]
    }
    """

  let response = try decoder.decode(AccountCollectionsResponse.self, from: Data(json.utf8))
  #expect(response.collections.count == 1)
  #expect(response.collections[0].name == "News organizations of Mastodon")
  #expect(response.collections[0].itemCount == 6)
}

@Test
func testAccountCollectionDecodingWithoutOptionalFields() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  let json = """
    {
      "id": "1",
      "account_id": "2",
      "uri": "https://example.com/ap/2/collections/1",
      "url": null,
      "name": "Minimal",
      "description": "",
      "language": null,
      "local": false,
      "sensitive": false,
      "discoverable": false,
      "tag": null,
      "item_count": 0,
      "items": [],
      "created_at": "2026-02-25T11:35:01.394Z",
      "updated_at": "2026-02-25T11:35:01.394Z"
    }
    """

  let collection = try decoder.decode(AccountCollection.self, from: Data(json.utf8))
  #expect(collection.url == nil)
  #expect(collection.language == nil)
  #expect(collection.tag == nil)
  #expect(collection.items.isEmpty)
  #expect(collection.acceptedAccountIds.isEmpty)
}

@Test
func testAccountCollectionItemDecodingWithoutAccount() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  let json = """
    {
      "id": "1",
      "account_id": null,
      "state": "revoked",
      "created_at": "2026-02-25T11:35:01.394Z"
    }
    """

  let item = try decoder.decode(AccountCollection.Item.self, from: Data(json.utf8))
  #expect(item.accountId == nil)
  #expect(item.state == "revoked")
}

@Test
func testAccountCollectionResponseDecoding() throws {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase

  let json = """
    {
      "collection": {
        "id": "1",
        "account_id": "2",
        "uri": "https://example.com/ap/2/collections/1",
        "url": "https://example.com/collections/1",
        "name": "People",
        "description": "",
        "language": null,
        "local": true,
        "sensitive": false,
        "discoverable": true,
        "tag": null,
        "item_count": 0,
        "items": [],
        "created_at": "2026-02-25T11:35:01.394Z",
        "updated_at": "2026-02-25T11:35:01.394Z"
      },
      "accounts": []
    }
    """

  let response = try decoder.decode(AccountCollectionResponse.self, from: Data(json.utf8))
  #expect(response.collection.name == "People")
  #expect(response.accounts.isEmpty)
}
