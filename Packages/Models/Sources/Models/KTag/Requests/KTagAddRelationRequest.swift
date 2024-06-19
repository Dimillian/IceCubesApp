//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation

public struct KTagAddRelationRequest:NotIdentifiedKTagAddRelationRequestDataProtocol, IdentifiedDataProtocol {
    public var isOwned: Bool
    
    public let kTagId: String
    
    public let statusId: String
    
    public let id: String
}

//public protocol KTagAddRelationRequest: NotIdentifiedKTagAddRelationRequestDataProtocol {
//    
//}
