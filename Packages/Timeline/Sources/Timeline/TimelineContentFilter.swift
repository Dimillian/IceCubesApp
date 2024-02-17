import Foundation
import SwiftUI

@MainActor
@Observable public class TimelineContentFilter {
  class Storage {
    @AppStorage("timeline_show_boosts") var showBoosts: Bool = true
    @AppStorage("timeline_show_replies") var showReplies: Bool = true
    @AppStorage("timeline_show_threads") var showThreads: Bool = true
    @AppStorage("timeline_quote_posts") var showQuotePosts: Bool = true
  }

  public static let shared = TimelineContentFilter()
  private let storage = Storage()

  public var showBoosts: Bool {
    didSet {
      storage.showBoosts = showBoosts
    }
  }

  public var showReplies: Bool {
    didSet {
      storage.showReplies = showReplies
    }
  }

  public var showThreads: Bool {
    didSet {
      storage.showThreads = showThreads
    }
  }

  public var showQuotePosts: Bool {
    didSet {
      storage.showQuotePosts = showQuotePosts
    }
  }

  private init() {
    showBoosts = storage.showBoosts
    showReplies = storage.showReplies
    showThreads = storage.showThreads
    showQuotePosts = storage.showQuotePosts
  }
}
