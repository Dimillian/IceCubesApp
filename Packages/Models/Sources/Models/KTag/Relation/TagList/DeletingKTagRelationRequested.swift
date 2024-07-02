//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//

import Foundation
// 消すリクエストが成功した場合　成功かつその場で消すことに成功した場合　失敗した場合すでにあるとか　で分けないとだめっぽいなぁ
public struct DeletingKTagRelationRequested: CreatedKTagAddRelationRequestDataProtocol{
    public let id: String // Ktag relation  id
    public let kTagId: String
    public let statusId: String
    public let accountId: String
    public let kTag: KTag
    public let isOwned: Bool
    public let kTagDeleteRelationRequest: KTagDeleteRelationRequest?
}


