import Foundation
import Env
import SwiftUI

@MainActor
@Observable public class TimelineContentFilter {
  public struct Snapshot: Sendable {
    public let showBoosts: Bool
    public let showReplies: Bool
    public let showThreads: Bool
    public let showQuotePosts: Bool
    public let hidePostsWithMedia: Bool

    public init(
      showBoosts: Bool,
      showReplies: Bool,
      showThreads: Bool,
      showQuotePosts: Bool,
      hidePostsWithMedia: Bool
    ) {
      self.showBoosts = showBoosts
      self.showReplies = showReplies
      self.showThreads = showThreads
      self.showQuotePosts = showQuotePosts
      self.hidePostsWithMedia = hidePostsWithMedia
    }
  }

  class Storage {
    @AppStorage("timeline_show_boosts") var showBoosts: Bool = true
    @AppStorage("timeline_show_replies") var showReplies: Bool = true
    @AppStorage("timeline_show_threads") var showThreads: Bool = true
    @AppStorage("timeline_quote_posts") var showQuotePosts: Bool = true
    @AppStorage("timeline_hide_posts_with_media") var hidePostsWithMedia: Bool = false
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
  
  public var hidePostsWithMedia: Bool {
    didSet {
      storage.hidePostsWithMedia = hidePostsWithMedia
    }
  }
    
  private init() {
    showBoosts = storage.showBoosts
    showReplies = storage.showReplies
    showThreads = storage.showThreads
    showQuotePosts = storage.showQuotePosts
    hidePostsWithMedia = storage.hidePostsWithMedia
  }

  public func snapshot() -> Snapshot {
    Snapshot(
      showBoosts: showBoosts,
      showReplies: showReplies,
      showThreads: showThreads,
      showQuotePosts: showQuotePosts,
      hidePostsWithMedia: hidePostsWithMedia
    )
  }
}
