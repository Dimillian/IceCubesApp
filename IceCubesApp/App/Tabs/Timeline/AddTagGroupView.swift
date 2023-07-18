import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import Shimmer
import SwiftUI

struct AddTagGroupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var theme: Theme
    
    @State private var title: String = ""
    @State private var sfSymbolName: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    
    private var canSave: Bool {
        !title.isEmpty &&
        // At least have 2 tags, one main and one additional.
            tags.count >= 2
    }
    
    @FocusState private var focusedField: Focus?
    
    enum Focus {
        case title
        case symbol
        case new
    }
    
    var body: some View {
        NavigationStack {
            Form {
                metadataSection
                keywordsSection
            }
            .formStyle(.grouped)
            .navigationTitle("timeline.filter.add-tag-groups")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(theme.secondaryBackgroundColor)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("action.cancel", action: { dismiss() })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("action.save", action: { save() })
                        .disabled(!canSave)
                }
            }
            .onAppear {
                focusedField = .title
            }
            .overlay(alignment: .bottom) {
                symbolsSuggestionView
            }
        }
    }
    
    @ViewBuilder
    private var metadataSection: some View {
        Section {
            TextField("add-tag-groups.edit.title.field", text: $title, axis: .horizontal)
                .focused($focusedField, equals: Focus.title)
                .onSubmit {
                    focusedField = Focus.symbol
                }
            
            HStack {
                TextField("add-tag-groups.edit.icon.field", text: $sfSymbolName, axis: .horizontal)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: Focus.symbol)
                    .onSubmit {
                        focusedField = Focus.new
                    }
                    .onChange(of: sfSymbolName) { name in
                        popupTagsPresented = true
                    }
                
                Image(systemName: sfSymbolName)
            }
        }
    }
    
    @State private var popupTagsPresented = false
     
    private var keywordsSection: some View {
        Section("add-tag-groups.edit.tags") {
            ForEach(tags, id: \.self) { tag in
                HStack {
                    Text(tag)
                    Spacer()
                    Button {
                        deleteTag(tag)
                    } label: {
                        Image(systemName: "trash")
                            .tint(.red)
                    }
                }
            }
            .onDelete { indexes in
                if let index = indexes.first {
                    let tag = tags[index]
                    deleteTag(tag)
                }
            }
            HStack {
                TextField("add-tag-groups.edit.tags.add", text: $newTag, axis: .horizontal)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        addNewTag()
                    }
                    .focused($focusedField, equals: Focus.new)
                Spacer()
                if !newTag.isEmpty {
                    Button {
                        addNewTag()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .tint(.green)
                    }
                }
            }
        }
        .listRowBackground(theme.primaryBackgroundColor)
    }
    
    private func addNewTag() {
        addTag(newTag.trimmingCharacters(in: .whitespaces))
        newTag = ""
        focusedField = Focus.new
    }
    
    private func addTag(_ tag: String) {
        guard !tag.isEmpty else { return }
        tags.append(tag)
    }
    
    private func deleteTag(_ tag: String) {
        tags.removeAll(where: { $0 == tag })
    }
    
    private func save() {
        var toSave = tags
        let main = toSave.removeFirst()
        preferences.tagGroups.append(.init(
            title: title.trimmingCharacters(in: .whitespaces),
            sfSymbolName: sfSymbolName,
            main: main,
            additional: toSave
        ))
        
        dismiss()
    }
    
    @ViewBuilder
    private var symbolsSuggestionView: some View {
        if focusedField == .symbol && !sfSymbolName.isEmpty {
            let filteredMatches = allSymbols
                .filter { $0.contains(sfSymbolName) }
            if !filteredMatches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(filteredMatches, id: \.self) { symbolName in
                            Button {
                                sfSymbolName = symbolName
                            } label: {
                                Image(systemName: symbolName)
                            }
                        }
                    }
                    .padding(.horizontal, .layoutPadding)
                }
                .frame(height: 40)
                .background(.ultraThinMaterial)
            }
        } else {
            EmptyView()
        }
    }
}



struct AddTagGroupView_Previews: PreviewProvider {
    static var previews: some View {
        AddTagGroupView()
            .withEnvironments()
    }
}
