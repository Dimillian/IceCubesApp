//
//  RSSAddNewFeed.swift
//
//
//  Created by Duong Thai on 07/03/2024.
//

import SwiftUI
import CoreData

public struct RSSAddNewFeed: View {
  @Environment(\.dismiss) private var dismiss

  @State private var state: MachineState = .emptyInput
  @State private var urlString = ""
  @State private var feed: RSSFeed? = nil
  @State private var downloadingTask: Task<(), Never>? = nil

  public enum Context { case manager, sheet }
  let context: Context

  public var body: some View {
    NavigationStack {
      Form {
        Section("rss.addNewFeed.url.textField.label") {
          VStack(alignment: .leading) {
            TextField("rss.addNewFeed.url.textField.placeholder", text: $urlString)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .keyboardType(.URL)
            
            IndicatorView(state: $state)
          }
        }

        FeedPreview(state: $state)
      }
      .navigationTitle("rss.addNewFeed.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if self.context == .sheet {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              dismiss()
              feed?.managedObjectContext?.rollback()
            } label: {
              Image(systemName: "xmark")
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("rss.addNewFeed.action.add") {
            dismiss()
            try? feed?.managedObjectContext?.save()
          }
        }
      }
      .onChange(of: urlString) {
        state = state.receive(urlString: urlString)
      }
      .onChange(of: state) {
        switch state {
        case .downloading(let url):
          downloadingTask?.cancel()
          feed?.managedObjectContext?.rollback()

          downloadingTask = Task {
            let rssFeed = await RSSTools.load(feedURL: url)
            if Task.isCancelled { return }
            if let rssFeed { self.state = .downloaded(feed: rssFeed, url: url) }
            else { self.state = .noData(url: url) }
          }
        case .downloaded(let feed, _):
          self.feed = feed
        default:
          downloadingTask?.cancel()
          feed?.managedObjectContext?.rollback()
        }
      }
      .onDisappear { feed?.managedObjectContext?.rollback() }
    }
  }

  public init(context: Context = .sheet) {
    self.context = context
  }

  private struct IndicatorView: View {
    @Binding var state: MachineState
    @State private var opacity: CGFloat = 1
    @State private var waitingDuration: TimeInterval = 0
    @State private var animatingTask: Task<(), Never>? = nil

    var body: some View {
      switch state {
      case .emptyInput, .downloaded:
        EmptyView()
      case .invalidURL, .noData:
        Text({
          if case .noData = state {
            "rss.addNewFeed.input.noData"
          } else {
            "rss.addNewFeed.input.invalidURL"
          }
        }())
        .font(.caption2)
        .foregroundStyle(.red)
      case .waiting, .downloading:
        Text({
          if case .waiting = state {
            "rss.addNewFeed.input.waiting"
          } else {
            "rss.addNewFeed.input.downloading"
          }
        }())
          .font(.caption2)
          .foregroundStyle(.green)
          .opacity(opacity)
          .task {
            waitingDuration = 0
            animatingTask?.cancel()

            animatingTask = Task {
              while true {
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { return }

                withAnimation(.easeInOut(duration: 0.5)) {
                  opacity = opacity == 1 ? 0 : 1
                }

                waitingDuration += 0.5
              }
            }
          }
          .onDisappear { animatingTask?.cancel() }
          .onChange(of: waitingDuration) {
            state = state.receive(waitingDuration: waitingDuration)
          }
      }
    }
  }

  private struct FeedPreview: View {
    @Binding var state: MachineState
    @State private var items: [RSSItem] = []

    var body: some View {
      if case let .downloaded(feed, _) = state {
        Section("rss.addNewFeed.feedPreview.label") {
          List(items) { item in
            RSSItemView(item)
          }
        }
        .task {
          items = ((feed.items?.allObjects as? [RSSItem]) ?? [])
            .sorted { i0, i1 in
              if let d0 = i0.date,
                 let d1 = i1.date
              {
                d0 > d1
              } else {
                false
              }
            }
        }
      }
    }
  }

  private enum MachineState: Equatable {
    case emptyInput
    case invalidURL(string: String)
    case waiting(url: URL)
    case downloading(url: URL)
    case downloaded(feed: RSSFeed, url: URL)
    case noData(url: URL)

    func receive(urlString: String) -> MachineState {
      if urlString.isEmpty {
        .emptyInput
      } else if let url = Self.validateURL(urlString) {
        .waiting(url: url)
      } else {
        .invalidURL(string: urlString)
      }
    }

    func receive(waitingDuration: TimeInterval) -> MachineState {
      switch self {
      case .waiting(let url) where waitingDuration >= 3:
          .downloading(url: url)
      default:
        self
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
}

#Preview {
  RSSAddNewFeed()
}
