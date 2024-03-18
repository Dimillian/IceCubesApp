//
//  RSSAddNewFeed.swift
//
//
//  Created by Duong Thai on 07/03/2024.
//

import SwiftUI
import CoreData

@MainActor
public struct RSSAddNewFeed: View {
  @Environment(\.dismiss) private var dismiss
  @State private var formVM = RSSAddNewFeedViewModel()
  @State private var urlString = ""
  let context: UIContext

  public var body: some View {
    NavigationStack {
      Form {
        Section("rss.addNewFeed.url.textField.label") {
          VStack(alignment: .leading) {
            TextField("rss.addNewFeed.url.textField.placeholder", text: $urlString)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .keyboardType(.URL)
              .onChange(of: urlString) {
                formVM.receive(urlString: urlString)
              }

            IndicatorView(formState: formVM.state)
          }
        }

        FeedPreview(formState: formVM.state)
          .id(UUID()) // A WORKAROUND TO DISABLE FORM CACHING TO MAKE ANIMATION CONSISTENT.

      }
      .navigationTitle("rss.addNewFeed.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if self.context == .sheet {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              dismiss()
              formVM.deleteFeed()
            } label: {
              Image(systemName: "xmark")
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("rss.addNewFeed.action.add") {
            formVM.state = .saved
            dismiss()
          }
        }
      }
      .onAppear {
        if context == .manager {
          try? RSSDataController.shared.viewContext.save()
        }
      }
      .onDisappear { formVM.deleteFeed() }
    }
  }

  public init(context: UIContext = .sheet) {
    self.context = context
  }

  public enum UIContext { case manager, sheet }
}

#Preview {
  RSSAddNewFeed()
}

private struct IndicatorView: View {
  private static let blinkingAnimation = Animation
    .easeInOut(duration: 0.5)
    .repeatForever()

  private let indicatorState: IndicatorState
  @State private var opacity: CGFloat = 1

  init(formState: FormState) { self.indicatorState = IndicatorState(formState) }

  var body: some View {
    switch indicatorState {
    case let .running(message):
      Text(message).font(.caption2).foregroundStyle(.green)
        .opacity(opacity)
        .onAppear {
          withAnimation(Self.blinkingAnimation) { opacity = opacity == 1 ? 0 : 1 }
        }
    case .warning(let message):
      Text(message).font(.caption2).foregroundStyle(.red)
    case .empty:
      EmptyView()
    }
  }
}

private enum IndicatorState: Equatable {
  case running(message: LocalizedStringKey)
  case warning(message: LocalizedStringKey)
  case empty

  init(_ formState: FormState) {
    switch formState {
    case .emptyInput, .downloaded(_), .saved:
      self = .empty
    case .invalidURL(_):
      self = .warning(message: "rss.addNewFeed.input.invalidURL")
    case .waiting(_):
      self = .running(message: "rss.addNewFeed.input.waiting")
    case .downloading(_):
      self = .running(message: "rss.addNewFeed.input.downloading")
    case .noData(_):
      self = .warning(message: "rss.addNewFeed.input.invalidURL")
    case .urlExists:
      self = .warning(message: "rss.addNewFeed.input.urlExists")
    }
  }
}

private struct FeedPreview: View {
  @FetchRequest private var items: FetchedResults<RSSItem>
  @State private var yOffset: CGFloat = 1000

  var body: some View {
    if !items.isEmpty {
      Section("rss.addNewFeed.feedPreview.label") {
        List(items, id: \.uniqueID) { item in
          RSSItemView(item)
        }
      }
      .offset(x: 0, y: yOffset)
      .onAppear {
        withAnimation(.easeInOut) { yOffset = 0 }
      }
    }
  }

  init(formState: FormState) {
    let urlString = if case let .downloaded(url) = formState { url.absoluteString } else { "" }
    self._items = FetchRequest(
      sortDescriptors: [SortDescriptor(\.date, order: .reverse)],
      predicate: NSPredicate(format: "%K = %@",
                             #keyPath(RSSItem.feed.feedURL.absoluteString),
                             urlString as CVarArg),
      animation: .easeInOut)
  }
}
