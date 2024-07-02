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
struct KTagSearchAndAddView : View, Sendable {
    @State private var searchText = ""
    var viewModel: KTagWithRelationListViewModel
    @State var selectedTag:[KTag] = []
    @State var client: Client?
    // 検索結果のフィルタリング
    @State var searchResults: [KTag] = []
    
    func fetchSearchResults() async {
        guard !searchText.isEmpty, let client = client else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await client.get(endpoint: KTagRequests.search(query: searchText, type: nil, offset: nil, following: nil))
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        VStack {
            // 選択されたタグの表示 追加候補になったら追加
//            if !self.selectedTag.isEmpty {
                Text("Selected Tags:")
                    .font(.headline)
                    .padding(.top)
                if !searchResults.isEmpty{
                    ForEach(selectedTag) { tag in
                        Button(action: {
                            Task{ 
                                await viewModel.del(tagId: tag.id) // Sending main actor-isolated 'self.viewModel' to nonisolated instance method 'del(tagId:)' risks causing data races between nonisolated and main actor-isolated uses
                            }
                            selectedTag.removeAll(where: {$0.id == tag.id})
                        }) {
                        Text(tag.name).font(.headline)
                        }
                    }
                }
            // 検索バー
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
            if !searchText.isEmpty {
                List {
                    ForEach(searchResults) { tag in
                        Button(action: {
                            Task{
                                await viewModel.addKTagRelationRequest(tagId: tag.id)
                            }
                            self.selectedTag.append(tag)
                        }) {
                            Text(tag.name)
                        }.foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    }
                }
                .listStyle(PlainListStyle())
            }
            

        }.onAppear(perform: {
//            selectedTag = viewModel.kTags
        })
//        .onDisappear(perform: {
//            //selectedTag - viewModel.kTags
//            // 差分を反映する。　無くなったタグを消去リクエスト　追加するタグを追加リクエスト
//            selectedTag.filter { elementA in
//                !viewModel.kTags.contains(where: { elementB in
//                    elementB == elementA
//                })}.map{viewModel.addKTagRelationRequest(tag: $0)}
//        })
    }
}

