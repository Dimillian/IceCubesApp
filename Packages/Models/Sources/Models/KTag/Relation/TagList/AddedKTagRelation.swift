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
    public var kTagDeleteRelationRequests:[KTagDeleteRelationRequest]
    public init(id: String, kTagId: String,statusId:String ,accountId: String,kTag:KTag, isOwned: Bool,kTagDeleteRelationRequests:[KTagDeleteRelationRequest]) {
        self.id = id
        self.kTagId = kTagId
        self.statusId = statusId
        self.accountId = accountId
        self.kTag = kTag
        self.isOwned = isOwned
        self.kTagDeleteRelationRequests = kTagDeleteRelationRequests
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kTagDeleteRelationRequests = []
//        try container.decode([KTagDeleteRelationRequest].self, forKey: .kTagDeleteRelationRequests)
        self.id = try container.decode(String.self, forKey: .id)
        self.kTagId = try container.decode(String.self, forKey: .kTagId)
        self.statusId = try container.decode(String.self, forKey: .statusId)
        self.accountId = try container.decode(String.self, forKey: .accountId)
        self.kTag = try container.decode(KTag.self, forKey: .kTag)
        self.isOwned = try container.decode(Bool.self, forKey: .isOwned)
        
    }
    
    public init( _ tag: DeletingKTagRelationRequested){
        self.id = tag.id
        self.kTagId = tag.kTagId
        self.statusId = tag.statusId
        self.accountId = tag.accountId
        self.kTag = tag.kTag
        self.isOwned = false
        if let r = tag.kTagDeleteRelationRequest {
            self.kTagDeleteRelationRequests = [r]
        } else {
            self.kTagDeleteRelationRequests = []
        }
    }
}
