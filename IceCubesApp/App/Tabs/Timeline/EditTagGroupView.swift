import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import Shimmer
import SwiftUI

@MainActor
struct EditTagGroupView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  @Environment(Theme.self) private var theme

  @State private var title: String = ""
  @State private var sfSymbolName: String = ""
  @State private var tags: [String] = []
  @State private var newTag: String = ""
  @State private var popupTagsPresented = false

  private var editingTagGroup: TagGroup?
  private var onSaved: ((TagGroup) -> Void)?
  
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

  init(editingTagGroup: TagGroup? = nil, onSaved: ((TagGroup) -> Void)? = nil) {
    self.editingTagGroup = editingTagGroup
    self.onSaved = onSaved
  }

  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        Form {
          metadataSection
          keywordsSection
        }
        .formStyle(.grouped)
        .navigationTitle(editingTagGroup != nil ? "timeline.filter.edit-tag-groups" : "timeline.filter.add-tag-groups")
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
        symbolsSuggestionView
      }
      .onAppear {
        focusedField = .title
        if let editingTagGroup {
          title = editingTagGroup.title
          sfSymbolName = editingTagGroup.symbolName
          tags = editingTagGroup.tags
        }
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
          .onChange(of: sfSymbolName) {
            popupTagsPresented = true
          }

        Image(systemName: sfSymbolName)
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

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
    if let editingTagGroup {
      editingTagGroup.title = title
      editingTagGroup.symbolName = sfSymbolName
      editingTagGroup.tags = tags
      onSaved?(editingTagGroup)
    } else {
      let tagGroup = TagGroup(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                              symbolName: sfSymbolName,
                              tags: tags)
      context.insert(tagGroup)
      onSaved?(tagGroup)
    }

    dismiss()
  }

  @ViewBuilder
  private var symbolsSuggestionView: some View {
    if focusedField == .symbol, !sfSymbolName.isEmpty {
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
    EditTagGroupView()
      .withEnvironments()
  }
}
