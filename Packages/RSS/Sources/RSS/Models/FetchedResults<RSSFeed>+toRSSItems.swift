//
//  FetchedResults<RSSFeed>+toRSSItems.swift
//
//
//  Created by Duong Thai on 14/3/24.
//

import SwiftUI

extension FetchedResults<RSSFeed> {
  func toRSSItems() -> [RSSItem] { self.flatMap { $0.toRSSItems() } }
}

extension RSSFeed {
  func toRSSItems() -> [RSSItem] { ((self.items?.allObjects as? [RSSItem]) ?? []) }
}

extension Optional<Date>: Comparable {
  public static func < (lhs: Optional, rhs: Optional) -> Bool {
    if let lhs, let rhs { lhs < rhs }
    else { false }
  }
  
  public static func > (lhs: Optional, rhs: Optional) -> Bool {
    if let lhs, let rhs { lhs > rhs }
    else { false }
  }

  public static func == (lhs: Optional, rhs: Optional) -> Bool {
    if let lhs, let rhs { lhs == rhs }
    else { false }
  }
}
