//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation

public struct KTagAddRelationRequestData: NotIdentifiedKTagAddRelationRequestDataProtocol{
    public var isOwned: Bool
    
    public let kTagId: String
    public let statusId: String
    public init( id : String ,kTagId: String, statusId: String, isOwned: Bool) {
        self.kTagId = kTagId
        self.statusId = statusId
        self.isOwned = isOwned
    }
}


