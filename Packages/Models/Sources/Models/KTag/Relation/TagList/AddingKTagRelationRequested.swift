//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation
import SwiftData
public struct AddingKTagRelationRequested :NotCreatedYetKTagRelationForSearchAndAddProtocol{
    public let tagRelationId: String?
    public let statusId: String
    public let accountId: String
    public let kTagId: String
    public let kTag: KTag
    public let kTagAddRelationRequest :KTagAddRelationRequest?
    public let isOwned: Bool
    public init(tagRelationId: String?, statusId: String, accountId: String, kTagId: String, kTag: KTag, kTagAddRelationRequest: KTagAddRelationRequest?, isOwned: Bool) {
        self.tagRelationId = tagRelationId
        self.statusId = statusId
        self.accountId = accountId
        self.kTagId = kTagId
        self.kTag = kTag
        self.kTagAddRelationRequest = kTagAddRelationRequest
        self.isOwned = isOwned
    }
}
