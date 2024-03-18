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
  var state: FormState = .emptyInput {
    didSet {
      self.cleanForTransitioning(from: oldValue, to: state)

      switch self.state {
      case .waiting(_):
        transitioningTask = createWaitingTask()
      case .downloading(_):
        transitioningTask = createDownloadingTask()
      default:
        return
      }
    }
  }

  @ObservationIgnored
  private var transitioningTask: Task<(), Never>? = nil

  func receive(urlString: String) {
    self.state = self.state.receive(urlString: urlString)
  }

  func deleteFeed(url: URL) {
    Task {
      if let feed = await RSSTools.fetchFeed(url: url) {
        feed.managedObjectContext?.delete(feed)
        try? feed.managedObjectContext?.save()
      }
    }
  }

  func deleteFeed() {
    Task { [state = self.state] in
      if case let .downloaded(url) = state,
         let feed = await RSSTools.fetchFeed(url: url)
      {
        feed.managedObjectContext?.delete(feed)
        try? feed.managedObjectContext?.save()
      }
    }
  }

  private func cleanForTransitioning(from oldState: FormState, to newState: FormState) {
    transitioningTask?.cancel()
    if case let .downloaded(url) = oldState,
       newState != .saved
    { self.deleteFeed(url: url) }
  }

  private func createWaitingTask() -> Task<(), Never>? {
    if case let .waiting(url) = state {
      Task {
        try? await Task.sleep(for: .seconds(0.2))

        if Task.isCancelled { return }
        self.state = .downloading(url: url)
      }
    } else {
      nil
    }
  }

  private func createDownloadingTask() -> Task<(), Never>? {
    if case let .downloading(url) = state {
      Task {
        if let _ = await RSSTools.fetchFeed(url: url) {
          if Task.isCancelled { return }
          self.state = .urlExists
          return
        }

        guard let _ = await RSSTools.load(feedURL: url)
        else {
          if Task.isCancelled { return }
          self.state = .noData(url: url)
          return
        }
        if Task.isCancelled { return }
        self.state = .downloaded(url: url)
      }
    } else {
      nil
    }
  }
}

enum FormState: Equatable {
  case emptyInput
  case invalidURL(string: String)
  case waiting(url: URL)
  case downloading(url: URL)
  case downloaded(url: URL)
  case noData(url: URL)
  case urlExists
  case saved

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

