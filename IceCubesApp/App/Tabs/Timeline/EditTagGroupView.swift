import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import Shimmer
import SwiftUI
import SwiftData
import SFSafeSymbols

@MainActor
struct EditTagGroupView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Environment(Theme.self) private var theme

  @State private var newTag: String = ""
  @State private var popupTagsPresented = false
  @State private var tagGroup: TagGroup
  @State private var symbolQuery = ""
  @State private var symbolSearchResult = [String]()
  @Query var tagGroups: [TagGroup]

  private let onSaved: ((TagGroup) -> Void)?
  private let isNewGroup: Bool

  @FocusState private var focusedField: Focus?

  enum Focus {
    case title
    case symbol
    case new
  }

  init(tagGroup: TagGroup = .emptyGroup(), onSaved: ((TagGroup) -> Void)? = nil) {
    self._tagGroup = State(wrappedValue: tagGroup)
    self.onSaved = onSaved
    self.isNewGroup = tagGroup.title.isEmpty
  }

  var body: some View {
    NavigationStack {
      Form {
        metadataSection
        keywordsSection
      }
      .formStyle(.grouped)
      .navigationTitle(
        isNewGroup
        ? "timeline.filter.add-tag-groups"
        : "timeline.filter.edit-tag-groups"
      )
      .navigationBarTitleDisplayMode(.inline)
      //        .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel", action: { dismiss() })
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("action.save", action: { save() })
            .disabled(!tagGroup.isValid)
        }
      }
      .onAppear {
        focusedField = .title
      }
    }
  }

  @ViewBuilder
  private var metadataSection: some View {
    Section {
      VStack(alignment: .leading) {
        TextField("add-tag-groups.edit.title.field", text: $tagGroup.title, axis: .horizontal)
          .focused($focusedField, equals: Focus.title)
          .onSubmit {
            focusedField = Focus.symbol
          }

        if focusedField == .title {
          if tagGroup.title.isEmpty {
            Text("Need a Non-Empty Title")
              .font(.caption)
              .foregroundStyle(.red)
          } else if
            isNewGroup,
            tagGroups.contains(where: { $0.title == tagGroup.title })
          {
            Text("\(tagGroup.title) Already Exists")
              .font(.caption)
              .foregroundStyle(.red)
          }
        }
      }

      VStack(alignment: .leading) {
        HStack {
          TextField("add-tag-groups.edit.icon.field", text: $symbolQuery, axis: .horizontal)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: Focus.symbol)
            .onSubmit {
              if TagGroup.allSymbols.contains(symbolQuery) {
                tagGroup.symbolName = symbolQuery
              }
              focusedField = Focus.new
            }
            .onChange(of: symbolQuery) {
              symbolSearchResult = TagGroup.searchSymbol(for: symbolQuery, exclude: tagGroup.symbolName)
            }
            .onChange(of: focusedField) {
              symbolQuery = tagGroup.symbolName
            }

          Image(systemName: tagGroup.symbolName)
            .frame(height: 30)
        }

        if tagGroup.symbolName.isEmpty,
           focusedField == .symbol
        {
          Text("Need to Select a Symbol")
            .font(.caption)
            .foregroundStyle(.red)
        }

        if focusedField == Focus.symbol {
          symbolsSuggestionView
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 40)
        }
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  var keywordsSection: some View {
    Section("add-tag-groups.edit.tags") {
      ForEach(tagGroup.tags, id: \.self) { tag in
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
          let tag = tagGroup.tags[index]
          deleteTag(tag)
        }
      }

      HStack {
        // this condition is using to overcome a SwiftUI bug
        // "add new tag" `TextField` is not focused after adding the first tag
        if tagGroup.tags.isEmpty {
          addNewTagTextField()
        } else {
          addNewTagTextField()
            .onAppear { focusedField = .new }
        }

        Spacer()

        if !newTag.isEmpty,
           !tagGroup.tags.contains(newTag)
        {
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

  private func addNewTagTextField() -> some View {
    VStack(alignment: .leading) {
      TextField("add-tag-groups.edit.tags.add", text: $newTag, axis: .horizontal)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit {
          addNewTag()
        }
        .focused($focusedField, equals: Focus.new)

      if focusedField == .new {
        if tagGroup.tags.count < 2 {
          Text("Need at Least 2 Tags to Form a Group")
            .font(.caption)
            .foregroundStyle(.red)
        }
        
        if tagGroup.tags.contains(newTag) {
          Text("Duplicated Tag")
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
    }
  }

  private func addNewTag() {
    addTag(newTag.trimmingCharacters(in: .whitespaces).lowercased())
    newTag = ""
    focusedField = Focus.new
  }

  // TODO: Show error and disable <Enter> for empty and duplicate tags
  private func addTag(_ tag: String) {
    guard !tag.isEmpty,
          !tagGroup.tags.contains(tag)
    else { return }

    tagGroup.tags.append(tag)
    tagGroup.tags.sort()
  }

  // TODO: make more sense to be a set
  private func deleteTag(_ tag: String) {
    tagGroup.tags.removeAll(where: { $0 == tag })
  }

  private func save() {
    tagGroup.format()
    context.insert(tagGroup)
    onSaved?(tagGroup)

    dismiss()
  }

  @ViewBuilder
  private var symbolsSuggestionView: some View {
    if symbolSearchResult.isEmpty {
      if symbolQuery == tagGroup.symbolName
          && !symbolQuery.isEmpty
          && symbolSearchResult.count == 0
      {
        Text("\(symbolQuery)").bold().italic() + Text(" are already selected.")
          .font(.caption)
          .foregroundStyle(.red)
      } else {
        Text("No Symbol Found")
      }
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(symbolSearchResult, id: \.self) { name in
            Button {
              symbolSearchResult = TagGroup.searchSymbol(for: symbolQuery, exclude: tagGroup.symbolName)
              tagGroup.symbolName = name
              symbolQuery = name
              focusedField = .new
            } label: {
              Image(systemName: name)
            }
            .buttonStyle(.plain)
          }
        }
        .animation(.spring(duration: 0.2), value: symbolSearchResult)
      }
      .onAppear {
        symbolSearchResult = TagGroup.searchSymbol(for: symbolQuery, exclude: tagGroup.symbolName)
      }
    }
  }
}

struct AddTagGroupView_Previews: PreviewProvider {
  static var previews: some View {
    let container = try? ModelContainer(for: TagGroup.self, configurations: ModelConfiguration())

    // need to use `sheet` to show `symbolsSuggestionView`
    return Text("parent view for EditTagGroupView")
      .sheet(isPresented: .constant(true)) {
        EditTagGroupView()
          .withEnvironments()
          .modelContainer(container!)
      }
  }
}

extension TagGroup {
  static func emptyGroup() -> TagGroup {
    TagGroup(title: "", symbolName: "", tags: [])
  }

  var isValid: Bool {
    !title.isEmpty &&
    tags.count >= 2 && // At least have 2 tags, one main and one additional.
    !symbolName.isEmpty
  }

  func format() {
    title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    tags = tags.map { $0.lowercased() }
  }

  static func searchSymbol(for query: String, exclude excludedSymbol: String) -> [String] {
    guard !query.isEmpty else { return [] }

    return Self.allSymbols.filter {
      $0.contains(query) &&
      $0 != excludedSymbol
    }
  }

  static let allSymbols: [String] = SFSymbol.allSymbols.map { symbol in
    symbol.rawValue
  }
}
