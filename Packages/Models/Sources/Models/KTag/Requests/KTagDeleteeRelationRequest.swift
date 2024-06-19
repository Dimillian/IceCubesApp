//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation


public struct KTagDeleteRelationRequest :Codable, Sendable{
    public let id: String
    public let kTagId: String
    public let targetRelationId :String
    public let requesterId: String
}
