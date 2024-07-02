//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation
import Network
import Models
import SwiftUICore

public class KTagWithRelationListViewModel : ObservableObject{
    public var kTagRelations: [AddedKTagRelation]
    public var addingKTagRelations: [AddingKTagRelationRequested]
    var client: Client?
    let statusId: String
    var kTags: [KTag]{
        get{
            kTagRelations.map{$0.kTag} +
            addingKTagRelations.map{ $0.kTag}
        }
    }
    
    public init( client: Client? = nil, statusId: String, kTagRelations: [AddedKTagRelation],addingKTagRelations: [AddingKTagRelationRequested]) {
        self.client = client
        self.statusId = statusId
        self.kTagRelations = kTagRelations
        self.addingKTagRelations = addingKTagRelations
    }
    
    // tagid ベースで消す　一致しているのを探す　見つかったのを消す
    func del(tagId :String) async{
        // すでの自分の削除リクエストがあるか
        if let delTarget = kTagRelations.filter({$0.kTagId == tagId && $0.isOwned}).first { // すでに送っているなら再度送る必要はなし 自分の削除リクエストがないなら削除リクエストを追加
            if let res = await try? await client?.post(endpoint: KTagDeleteRelationRequests.create(json: KTagDeleteRelatioonRequestData.init(k_tag_relation_id: delTarget.id))) as?  DeletingKTagRelationRequested {
                // レスポンスでその場で削除できた場合
                if let ktag = res.kTagDeleteRelationRequest{
                    if var updatedDelTarget = kTagRelations.first(where: { $0.id == delTarget.id }) {
                                        updatedDelTarget.kTagDeleteRelationRequests.append(ktag)
                                        if let index = kTagRelations.firstIndex(where: { $0.id == delTarget.id }) {
                                            kTagRelations[index] = updatedDelTarget
                                        }
                                    }
                } else{
                    addingKTagRelations.removeAll(where:{$0.kTagId == tagId})
                }
            }
        } else if let delTarget = addingKTagRelations.filter({$0.kTagAddRelationRequest?.isOwned ?? false && $0.kTagId == tagId}).first?.kTagAddRelationRequest{
            if let res = try? await client?.post(endpoint: KTagAddRelationRequests.delete(id: delTarget.id)) as?  KTagAddRelationRequest{
                addingKTagRelations.removeAll(where:{$0.kTagId == tagId})
            }
//            消せたら削除　失敗は　対象なしなら４０４で返すべき？失敗なら必ず消すべきとも限らなさそうだが　おかしくなったらリロードすりゃいいだけのはなしか。
//            前の画面に戻ったらツイート丸ごとリロードが走るはず
        }
    }
    
    // 何もないところから追加 追加リクエストをする　成功したら追加　　他人の物の場合
    func addKTagRelationRequest(tagId: String) async {
        if let res = try? await client?.post(endpoint: KTagAddRelationRequests.create(json: KTagAddRelatioonRequestData.init(k_tag_id: tagId, status_id: statusId))) as? AddingKTagRelationRequested {
//            自分のものの場合ZZ
            if (res.tagRelationId != nil) && res.isOwned {
                kTagRelations.append(AddedKTagRelation.init(id: res.tagRelationId!, kTagId: res.kTagId, statusId: statusId, accountId: res.accountId, kTag: res.kTag, isOwned: res.isOwned, kTagDeleteRelationRequests: []))
            } else{
                addingKTagRelations.append(res)
            }
        }
        
    }
//    
//        // 消そうとしてた 消すリクエストを削除
//    func addKTagRelationRequest(kTagRelation: DeletingKTagRelationRequested) async {
//        guard let res = try? await client?.post(endpoint: KTagDeleteRelationRequests.delete(id: kTagRelation.kTagDeleteRelationRequest.id)) as? AddedKTagRelation else{ return }
//        kTagRelations.remove(kTagRelation)
//        kTagRelations.update(AddedKTagRelation.init(kTagRelation))
//    }
}
