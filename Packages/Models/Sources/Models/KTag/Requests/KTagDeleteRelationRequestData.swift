//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation

public struct KTagDeleteRelationRequestData: Codable,Sendable{
    let id : String
    let kTagRelationId: String
    public init(id: String, kTagRelationId: String) {
        self.id = id
        self.kTagRelationId = kTagRelationId
    }
}
