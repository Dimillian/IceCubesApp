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

  // MARK: - interface
  private(set) var state: FormState = .emptyInput {
    didSet { self.transition(from: oldValue, to: state) }
  }

  // MARK: - UI actions

  func receive(urlString: String) {
    self.state = self.state.receive(urlString: urlString)
  }

  func save() {
    let context = RSSDataController.shared.viewContext
    if context.hasChanges { try? context.save() }
  }

  func dismiss() {
    self.deleteFeed()
    self.dismissAction?()
  }

  func done() {
    self.state = .saved
  }

  func setDismissAction(_ action: DismissAction) {
    self.dismissAction = action
  }

  // MARK: - private

  private var dismissAction: DismissAction? = nil

  @ObservationIgnored
  private var transitioningTask: Task<(), Never>? = nil

  private func deleteFeed(url: URL) {
    Task {
      if let feed = await RSSTools.fetchFeed(url: url) {
        feed.managedObjectContext?.delete(feed)
        try? feed.managedObjectContext?.save()
      }
    }
  }

  private func deleteFeed() {
    Task { [state = self.state] in
      if case let .downloaded(url) = state,
         let feed = await RSSTools.fetchFeed(url: url)
      {
        feed.managedObjectContext?.delete(feed)
        try? feed.managedObjectContext?.save()
      }
    }
  }

  private func transition(from oldState: FormState, to newState: FormState) {
    print("transition: \(oldState) -> \(newState)\n----")

    transitioningTask?.cancel()

    switch oldState {
    case .downloaded(let oldURL):
      switch newState {
      case .waiting(_):
        self.deleteFeed(url: oldURL)
        self.transitioningTask = createWaitingTask()
      case .downloading(_):
        self.deleteFeed(url: oldURL)
        self.transitioningTask = createDownloadingTask()
      case .saved:
        dismissAction?()
      case .downloaded(_):
        return
      default:
        self.deleteFeed(url: oldURL)
      }
    case .saved:
      return
    default:
      switch newState {
      case .waiting(_):
        self.transitioningTask = createWaitingTask()
      case .downloading(_):
        self.transitioningTask = createDownloadingTask()
      default:
        return
      }
    }
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

