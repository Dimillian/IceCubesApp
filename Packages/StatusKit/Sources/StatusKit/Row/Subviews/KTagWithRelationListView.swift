//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/12.
//

import Foundation
import SwiftUI
import Network
import Models
import Env
@MainActor
struct KTagSearchAndAddView : View {
    @State private var selectedTexts: [String] = []
        let buttonTexts = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    @State private var searchText = ""
   var viewModel: StatusRowViewModel
    @State private var selectedTag:[KTag] = []
    // 検索結果のフィルタリング
    @State private var searchResults: [KTag] = []
    @Environment(StatusDataController.self) private var statusDataController
    func fetchSearchResults() async {
        do {
            searchResults = try await viewModel.client.get(endpoint: KTagRequests.search(query: searchText, type: nil, offset: nil, following: nil))
        } catch {
            print(error)
        }
    }
    // リストアイテムの削除機能
    func deleteItem(_ item: String) {
            if let index = selectedTexts.firstIndex(of: item) {
                selectedTexts.remove(at: index)
            }
        }

    var body: some View {
        
                    
                    // 選択されたテキストのリスト表示
            
        VStack {
            TextField("Search", text: $searchText)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                .onChange(of: searchText) {
                    Task {
                        await fetchSearchResults()
                    }
                }
            // 検索候補の表示
            if !searchResults.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(searchResults, id: \.id) { tag in
                            Button(action: { // このボタンをタップすると、selectedTag　に追加されるようにして
                                                            Task{
                                                                await viewModel.addKTagRelationRequest(tagId: tag.id)
                                                            }
                                selectedTag.append(tag)
                            }) {
                                Text(tag.name)
                            }.foregroundColor(.blue)
                                .background(Color(.systemGray6))
                                .cornerRadius(8).padding()
                        }
                    }}
            }
            Text("Added Tags:")
                .font(.headline)
                .padding(.top)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack{
                    ForEach(statusDataController.kTagRelations.filter({$0.kTagDeleteRelationRequests.isEmpty}), id: \.kTag.id) { kTagRelation in
                        Button(action: {
                            Task {
                                await viewModel.del(tagId: kTagRelation.kTag.id)
                            }
                        }) {
                            Text("x:" + kTagRelation.kTag.name).font(.headline)
                        }.foregroundColor(.blue)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    ForEach(statusDataController.kTagRelations.filter({!$0.kTagDeleteRelationRequests.isEmpty}), id: \.kTag.id) { kTagRelation in
                        Button(action: {
                            
                        }) {
                            Text( kTagRelation.kTag.name).font(.headline).strikethrough(color: .red)
                        }
                    }
                }
            }
            
            
        }
    }
    
}

