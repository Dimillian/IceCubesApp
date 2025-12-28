import Foundation
import Models

func makeStatus(id: String, hidden: Bool) -> Status {
  let base = Status.placeholder()
  let filtered: [Filtered]? = hidden ? [makeHiddenFilter()].compactMap { $0 } : nil

  return Status(
    id: id,
    content: base.content,
    account: base.account,
    createdAt: base.createdAt,
    editedAt: base.editedAt,
    reblog: base.reblog,
    mediaAttachments: base.mediaAttachments,
    mentions: base.mentions,
    repliesCount: base.repliesCount,
    reblogsCount: base.reblogsCount,
    favouritesCount: base.favouritesCount,
    card: base.card,
    favourited: base.favourited,
    reblogged: base.reblogged,
    pinned: base.pinned,
    bookmarked: base.bookmarked,
    emojis: base.emojis,
    url: base.url,
    application: base.application,
    inReplyToId: base.inReplyToId,
    inReplyToAccountId: base.inReplyToAccountId,
    visibility: base.visibility,
    poll: base.poll,
    spoilerText: base.spoilerText,
    filtered: filtered,
    sensitive: base.sensitive,
    language: base.language,
    tags: base.tags,
    quote: nil,
    quotesCount: nil,
    quoteApproval: nil)
}

private func makeHiddenFilter() -> Filtered? {
  let json = """
    {
      "filter": {
        "id": "filter",
        "title": "Hidden",
        "context": ["home"],
        "filterAction": "hide"
      },
      "keywordMatches": null
    }
    """

  return try? JSONDecoder().decode(Filtered.self, from: Data(json.utf8))
}
