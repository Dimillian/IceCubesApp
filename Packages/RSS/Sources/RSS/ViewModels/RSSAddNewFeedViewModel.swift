//
//  RSSAddNewFeedViewModel.swift
//  
//
//  Created by Duong Thai on 17/3/24.
//

import SwiftUI

@MainActor
@Observable
final class RSSAddNewFeedViewModel {
  var feed: RSSFeed? = nil
  var state: FormState = .emptyInput {
    didSet {
      transitionTask?.cancel()
      if let feed {
        feed.managedObjectContext?.delete(feed)
        try? feed.managedObjectContext?.save()
      }

      switch self.state {
      case .waiting(let url):
        transitionTask = Task {
          try? await Task.sleep(for: .seconds(3))

          if Task.isCancelled { return }
          self.state = .downloading(url: url)
        }
      case .downloading(let url):
        transitionTask = Task {
          if let _ = await RSSTools.fetchFeed(url: url) {
            if Task.isCancelled { return }
            self.state = .urlExists
            return
          }

          guard let _ = await RSSTools.load(feedURL: url),
                let rssFeed = await RSSTools.fetchFeed(url: url)
          else {
            if Task.isCancelled { return }
            self.state = .noData(url: url)
            return
          }
          if Task.isCancelled { return }
          self.state = .downloaded(feed: rssFeed, url: url)
        }
      case .downloaded(let feed, _):
        self.feed = feed
      default:
        return
      }
    }
  }

  var items: [RSSItem] {
    feed?.toRSSItems().sorted { $0.date > $1.date }
    ?? []
  }

  @ObservationIgnored
  private var transitionTask: Task<(), Never>? = nil

  func receive(urlString: String) {
    self.state = self.state.receive(urlString: urlString)
  }
}

enum FormState: Equatable {
  case emptyInput
  case invalidURL(string: String)
  case waiting(url: URL)
  case downloading(url: URL)
  case downloaded(feed: RSSFeed, url: URL)
  case noData(url: URL)
  case urlExists

  func receive(urlString: String) -> FormState {
    if urlString.isEmpty {
      .emptyInput
    } else if let url = Self.validateURL(urlString) {
      .waiting(url: url)
    } else {
      .invalidURL(string: urlString)
    }
  }

  private static func validateURL(_ string: String) -> URL? {
    // TODO: improve this
    guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    let pattern = "^(http|https)://"

    let newURLString: String
    if let _ = string.range(of: pattern, options: .regularExpression) {
      newURLString = string
    } else {
      newURLString = "https://\(string)"
    }

    return URL(string: newURLString)
  }
}

