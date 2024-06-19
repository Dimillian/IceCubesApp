//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation

public struct DeletingKTagRelationRequested: CreatedKTagAddRelationRequestDataProtocol{
    public let id: String
    public let kTagId: String
    public let statusId: String
    public let accountId: String
    public let kTag: KTag
    public let isOwned: Bool
    public let kTagDeleteRelationRequest: KTagDeleteRelationRequest
}


