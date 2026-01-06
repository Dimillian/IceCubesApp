//
//  TimelineDataSourceFilterTests.swift
//  Timeline
//
//  Created by Dshynt Pwr on 28/12/25.
//
import Testing
import Foundation
@testable import Timeline
@testable import Models
@testable import Env

@Suite("TimelineDatasource media filter")
struct TimelineDatasourceMediaFilterTests {
    
    //Helper to build a Status with a given number of media attachments
    private func makeStatus(id: String, mediaCount: Int) -> Status {
        return Status(
            id: id,
            content: .init(stringValue: "", parseMarkdown: false),
            account: .placeholder(),
            createdAt: ServerDate(),
            editedAt: nil,
            reblog: nil,
            mediaAttachments: makeAttachments(mediaCount: mediaCount),
            mentions: [],
            repliesCount: 0,
            reblogsCount: 0,
            favouritesCount: 0,
            card: nil,
            favourited: nil,
            reblogged: nil,
            pinned: nil,
            bookmarked: nil,
            emojis: [],
            url: nil,
            application: nil,
            inReplyToId: nil,
            inReplyToAccountId: nil,
            visibility: .pub,
            poll: nil,
            spoilerText: .init(stringValue: ""),
            filtered: [],
            sensitive: false,
            language: nil,
            tags: [],
            quote: nil,
            quotesCount: nil,
            quoteApproval: nil
        )
    }
    
    private func makeAttachments(mediaCount: Int) -> [MediaAttachment] {
        guard mediaCount > 0 else { return [] }
        return (0..<mediaCount).map { idx in
            let url = URL(string: "https://example.com/media/\(idx).jpg")
            return MediaAttachment.imageWith(url: url!)
        }
    }
    
    @Test("Hides posts that contain media when the setting is ON")
    func hidePostsWithMediaWhenEnabled() {
        let a = makeStatus(id: "a", mediaCount: 0)
        let b = makeStatus(id: "b", mediaCount: 2)
        let c = makeStatus(id: "c", mediaCount: 1)
        let d = makeStatus(id: "d", mediaCount: 0)
        let input = [a, b, c, d]
        
        //When
        let hidePostsWithMedia = true
        let output = input.filter { status in
            hidePostsWithMedia ? status.mediaAttachments.isEmpty : true
        }
        
        //Then
        #expect(output.map(\.id) == ["a", "d"])
    }
    
    @Test("Show all posts when the setting is OFF")
    func showAllPostsWhenDisabled() {
        let a = makeStatus(id: "a", mediaCount: 0)
        let b = makeStatus(id: "b", mediaCount: 2)
        let c = makeStatus(id: "c", mediaCount: 0)
        let input = [a, b, c]
        
        //When
        let hidePostsWithMedia = false
        let output = input.filter { status in
            hidePostsWithMedia ? status.mediaAttachments.isEmpty : true
        }
        
        //Then
        #expect(output.map(\.id) == ["a", "b", "c"])
    }
    
}
