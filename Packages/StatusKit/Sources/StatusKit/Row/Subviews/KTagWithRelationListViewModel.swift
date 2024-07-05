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
import OSLog

@MainActor
@Observable public class KTagWithRelationListViewModel : ObservableObject{
    public var kTagRelations: [AddedKTagRelation]
    public var addingKTagRelations: [AddingKTagRelationRequested]
    var client: Client?
    let statusId: String
    private let logger = Logger(subsystem: "com.icecubesapp", category: "KTagWithRelationListViewModel")
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
    // tagId ベースで消す　一致しているのを探す　見つかったのを消す
    func del(tagId: String) async {
        guard let client = self.client else {
            print("Client is not initialized")
            return
        }

        // Check for existing delete requests
        if let delTarget = kTagRelations.first(where: { $0.kTagId == tagId && $0.isOwned }) {
            do {
                let deleteRequest = KTagDeleteRelatioonRequestData(k_tag_relation_id: delTarget.id)
                let (data, response) = try await client.postWithData(endpoint: KTagDeleteRelationRequests.create(json: deleteRequest))
                if let httpResponse = response as? HTTPURLResponse, (404...404).contains(httpResponse.statusCode){
                    kTagRelations.removeAll(where: { $0.kTagId == tagId })
                                    return
                }
                logger.log(level: .info, "\(data)")
                // Decode the response
                let decoder = JSONDecoder()
                if let ktag = try? decoder.decode(KTagDeleteRelationRequest.self, from: data) {
                    // Update kTagRelations
                    if var updatedDelTarget = kTagRelations.first(where: { $0.id == delTarget.id }) {
                        updatedDelTarget.kTagDeleteRelationRequests.append(ktag)
                        if let index = kTagRelations.firstIndex(where: { $0.id == delTarget.id }) {
                            kTagRelations[index] = updatedDelTarget
                        }
                    }
                } else if let kTag :AddedKTagRelation = try? decoder.decode(AddedKTagRelation.self, from: data) {//Initializer for conditional binding must have Optional type, not
                    kTagRelations.removeAll(where: { $0.kTagId == kTag.kTagId })
                }
                
            } catch {
                print("Error deleting KTag relation: \(error.localizedDescription)")
            }
        } else if let delTarget = addingKTagRelations.first(where: { $0.kTagAddRelationRequest?.isOwned ?? false && $0.kTagId == tagId })?.kTagAddRelationRequest {
            do {
                let (data, _) = try await client.postWithData(endpoint: KTagAddRelationRequests.delete(id: delTarget.id))
                // Decode the response
                let decoder = JSONDecoder()
                if let kTagAddRelationRequest :KTagAddRelationRequest = try? decoder.decode(KTagAddRelationRequest.self, from: data) {
                    addingKTagRelations.removeAll(where: { $0.kTagId == kTagAddRelationRequest.kTagId })
                }
            } catch {
                print("Error deleting KTag add relation request: \(error.localizedDescription)")
            }
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
