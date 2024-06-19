//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation
import Network
import Models

@MainActor
public class KTagWithRelationListViewModel : ObservableObject{
    @Published public var kTagRelations: KTagRelations
    var client: Client?
    var statusId: String
    var kTags: [KTag]{
        get{
            kTagRelations.addedKTagRelationList.map{$0.kTag} +
            kTagRelations.deletingKTagRelationRequestedList.map{ $0.kTag} +
            kTagRelations.addingKTagRelationRequestedList.map{ $0.kTag}
        }
    }
    
    public init(kTagRelations: KTagRelations, client: Client? = nil,statusId: String) {
        self.kTagRelations = kTagRelations
        self.client = client
        self.statusId = statusId
    }
    // tagid ベースで消す　一致しているのを探す　見つかったのを消す
    func del(tagId :String){
        guard let r  = kTagRelations.addedKTagRelationList.filter({$0.kTagId == tagId}).first else{
            guard let j  = kTagRelations.deletingKTagRelationRequestedList.filter({$0.kTagId == tagId}).first else {
                guard let i  = kTagRelations.addingKTagRelationRequestedList.filter({$0.kTagId == tagId}).first else {return}
                kTagRelations.addingKTagRelationRequestedList.remove(i)
                return
            }
            kTagRelations.deletingKTagRelationRequestedList.remove(j)
            return
        }
        kTagRelations.addedKTagRelationList.remove(r)
    }
    //削除する対象になる　それで削除できてリクエストが消されたら、リクエスト済みにする　クラスを入れ替える　自分のものだったら消す　他人のものでも削除リクエスト済みのタグを返す　返ってこない間はどうすりゃいいの？ adding に入っていたら取り消し　でも投げるエンドポイントは同じ
    func deleteKTagRelationRequest(kTagRelation: AddedKTagRelation) async {
        kTagRelations.remove(kTagRelation)
        guard let res = try? await client?.post(endpoint: KTagDeleteRelationRequests.create(json: KTagDeleteRelatioonRequestData.init(k_tag_relation_id: kTagRelation.id))) as?  DeletingKTagRelationRequested else{ return kTagRelations.update(kTagRelation)  }// erro Type of expression is ambiguous without a type annotation
        kTagRelations.update(res)
    }
    
    // 追加したいリクエストを出しているタグだったら、　追加リクエストを消して　現在の候補からも削除する
    func deleteKTagRelationRequest(kTagRelation: AddingKTagRelationRequested) async {
        guard let res = try? await client?.post(endpoint: KTagAddRelationRequests.delete(id: kTagRelation.kTagAddRelationRequest.id)) as?  KTagAddRelationRequest else{ return  }
        kTagRelations.remove(kTagRelation)
    }
    
    // 何もないところから追加
    func addKTagRelationRequest(tagId: String) async {
        guard let res = try? await client?.post(endpoint: KTagAddRelationRequests.create(json: KTagAddRelatioonRequestData.init(k_tag_id: tagId, status_id: statusId))) as? AddingKTagRelationRequested else{ return }
        kTagRelations.update(res)
    }
    
        // 消そうとしてた 消すリクエストを削除
    func addKTagRelationRequest(kTagRelation: DeletingKTagRelationRequested) async {
        guard let res = try? await client?.post(endpoint: KTagDeleteRelationRequests.delete(id: kTagRelation.kTagDeleteRelationRequest.id)) as? AddedKTagRelation else{ return }
        kTagRelations.remove(kTagRelation)
        kTagRelations.update(AddedKTagRelation.init(kTagRelation))
    }
}
