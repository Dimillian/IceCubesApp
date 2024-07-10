//
//  KTagWithRelatidddsonListView.swift
//  
//
//  Created by keisuke koyanagi on 2024/07/02.
//

import Foundation
import SwiftUI
import Network
import Models
import Env

struct KTagWithRelationListView: View {
    var viewModel: StatusRowViewModel
    @State private var showAlert = false
    @Environment(StatusDataController.self) private var statusDataController
    // stream から削除信号が来たらタグを消す
    var body: some View {
        HStack{
            ForEach(statusDataController.kTagRelations, id: \.kTagId){ kTagRelation in
                Button(action: {
                    Task{
                        await viewModel.del(tagId: kTagRelation.kTagId)
                    }
                }, label: {
                    Text(kTagRelation.kTag.name)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                })
            }
        }
    }
    
    func color(_ tag: any NotIdentifiedKTagAddRelationRequestDataProtocol) -> Color {
        switch tag {
            case is AddingKTagRelationRequested:
                if (tag.isOwned){
                    return .purple
                } else{
                    return .blue
                }
            case is DeletingKTagRelationRequested:
                if (tag.isOwned){
                    return .red
                } else{
                    return .yellow
                }
        case is AddedKTagRelation:
            return .clear // Doubleの場合は緑色
        default:
                return .clear // 他の型の場合は灰色
        }
    }
    
}
