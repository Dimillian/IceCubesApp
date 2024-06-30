//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation
import SwiftData
public struct AddingKTagRelationRequested :NotCreatedYetKTagRelationForSearchAndAddProtocol{
  
    public let statusId: String
    public let accountId: String
    public let kTagId: String
    public let kTag: KTag
    public let kTagAddRelationRequest :KTagAddRelationRequest
    public let isOwned: Bool
}
