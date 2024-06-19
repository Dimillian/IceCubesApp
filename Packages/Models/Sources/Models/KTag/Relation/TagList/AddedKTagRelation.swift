//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation

public struct AddedKTagRelation :CreatedKTagAddRelationRequestDataProtocol, Sendable{
    
    public let id: String
    public let kTagId: String
    public let statusId: String
    public let accountId: String
    public let kTag: KTag
    public var isOwned: Bool
    public init(id: String, kTagId: String,statusId:String ,accountId: String,kTag:KTag, isOwned: Bool) {
        self.id = id
        self.kTagId = kTagId
        self.statusId = statusId
        self.accountId = accountId
        self.kTag = kTag
        self.isOwned = isOwned
    }
    
    public init( _ tag: DeletingKTagRelationRequested){
        self.id = tag.id
        self.kTagId = tag.kTagId
        self.statusId = tag.statusId
        self.accountId = tag.accountId
        self.kTag = tag.kTag
        self.isOwned = false
    }
}
