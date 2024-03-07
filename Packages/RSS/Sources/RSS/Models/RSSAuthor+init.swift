//
//  RSSAuthor+init.swift
//
//
//  Created by Duong Thai on 05/03/2024.
//

import CoreData
import RSParser

extension RSSAuthor {
  public convenience init?(
    context: NSManagedObjectContext,
    parsedAuthor: ParsedAuthor,
    feedURL: URL
  ) {
    self.init(context: context)

    guard let displayName = [
      parsedAuthor.name,
      parsedAuthor.emailAddress,
      parsedAuthor.url,
      parsedAuthor.avatarURL
    ].compactMap({ $0 }).first
    else { return nil }

    self.id = feedURL.appending(path: "ica-rss-author/\(displayName)")
    self.displayName = displayName

    self.name = parsedAuthor.name

    self.url = if let url = parsedAuthor.url { URL(string: url) } else { nil }
    self.avatarURL = if let avatarURL = parsedAuthor.avatarURL { URL(string: avatarURL) } else { nil }
    //    self.email = if let email = parsedAuthor.emailAddress { RSSEmail(email) } else { nil }
    self.email = if let email = parsedAuthor.emailAddress { email } else { nil }
  }
}
