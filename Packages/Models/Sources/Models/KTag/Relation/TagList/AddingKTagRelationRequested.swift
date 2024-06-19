//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation
public struct AddingKTagRelationRequested :NotCreatedYetKTagRelationForSearchAndAddProtocol, Sendable{
  
    public let statusId: String
    public let accountId: String
    public let kTagId: String
    public let kTag: KTag
    public let kTagAddRelationRequest :KTagAddRelationRequest
    public let isOwned: Bool
    init(kTagId: String,statusId:String ,accountId: String,kTag:KTag, kTagAddRelationRequest :KTagAddRelationRequest, isOwned: Bool) {
        self.statusId = statusId
        self.accountId = accountId
        self.kTag = kTag
        self.kTagAddRelationRequest = kTagAddRelationRequest
        self.kTagId = kTagId
        self.isOwned = isOwned
    }
}
