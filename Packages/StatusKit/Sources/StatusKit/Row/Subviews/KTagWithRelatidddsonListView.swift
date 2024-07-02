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
struct KTagWithRelationListView: View {
    @State var viewModel: KTagWithRelationListViewModel
    var client: Client?
    @State private var showAlert = false
   
    // stream から削除信号が来たらタグを消す
    var body: some View {
        HStack{
            
            ForEach(viewModel.kTags){ kTagRelation in
                Button(action: {
                    showAlert = true
                }, label: {
                    Text(kTagRelation.name)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                })
//                .foregroundColor(color(kTagRelation))
//                    .alert(isPresented: $showAlert) {
//                        Alert(
//                            title: Text("Confirmation"),
//                            message: Text("Do you want to proceed?"),
//                            primaryButton: .default(Text("OK"), action: {
////                                Task {
////                                    await viewModel.deleteKTagRelationRequest(kTagRelation: kTagRelation)
////                                }
//                            }),
//                            secondaryButton: .cancel()
//                        )
//                    }
            }
//            let array2 = Array(viewModel.kTagRelations.addingKTagRelationRequestedList)
//            ForEach(array2, id: \.kTagId){ kTagRelation in
//                Button(action: {
//                    showAlert = true
//                }, label: {
//                    Text(kTagRelation.kTag.name)
//                        .padding(4)
//                        .background(Color.blue.opacity(0.2))
//                        .cornerRadius(8)
//                }).foregroundColor(color(kTagRelation))
//                    .alert(isPresented: $showAlert) {
//                        Alert(
//                            title: Text("Confirmation"),
//                            message: Text("Do you want to proceed?"),
//                            primaryButton: .default(Text("OK"), action: {
//                                Task {
//                                    await viewModel.deleteKTagRelationRequest(kTagRelation: kTagRelation)
//                                }
//                            }),
//                            secondaryButton: .cancel()
//                        )
//                    }
//        }
//
//            let array3  = Array(viewModel.kTagRelations.deletingKTagRelationRequestedList)
//            ForEach(array3, id: \.id){ kTagRelation in
//                Button(action: {
//                    showAlert = true
//                }, label: {
//                    Text(kTagRelation.kTag.name)
//                        .padding(4)
//                        .background(Color.blue.opacity(0.2))
//                        .cornerRadius(8)
//                }).foregroundColor(color(kTagRelation))
//                    .alert(isPresented: $showAlert) {
//                        Alert(
//                            title: Text("Confirmation"),
//                            message: Text("Do you want to proceed?"),
//                            primaryButton: .default(Text("OK"), action: {
//                                Task {
//                                    await viewModel.addKTagRelationRequest(kTagRelation: kTagRelation)//Sending main actor-isolated 'self.viewModel' to nonisolated instance method 'addKTagRelationRequest(kTagRelation:)' risks causing data races between nonisolated and main actor-isolated uses
//                                }
//                            }),
//                            secondaryButton: .cancel()
//                        )
//                    }
//            }
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
