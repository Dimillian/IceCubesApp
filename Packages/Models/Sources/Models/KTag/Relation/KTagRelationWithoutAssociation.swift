//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation

protocol KTagRelationProtocol:NotIdentifiedKTagAddRelationRequestDataProtocol,Identifiable,Codable{
    var id: String{get}
    var accountId: String{get}
}

public struct KTagRelationWithoutAssociation :KTagRelationProtocol, Sendable{
    public var isOwned: Bool
    public let id: String
    public let kTagId: String
    public let statusId: String
    public let accountId: String
    init(id: String, kTagId: String,statusId:String 
         ,accountId: String, isOwned: Bool) {
        self.id = id
        self.kTagId = kTagId
        self.statusId = statusId
        self.accountId = accountId
        self.isOwned = isOwned
    }
}
