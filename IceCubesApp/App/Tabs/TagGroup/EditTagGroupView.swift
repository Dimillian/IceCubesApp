import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SFSafeSymbols
import SwiftData
import SwiftUI

@MainActor
struct EditTagGroupView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Environment(Theme.self) private var theme

  @State private var tagGroup: TagGroup

  private let onSaved: ((TagGroup) -> Void)?
  private let isNewGroup: Bool

  @FocusState private var focusedField: Focus?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TitleInputView(
            title: $tagGroup.title,
            titleValidationStatus: tagGroup.titleValidationStatus,
            focusedField: $focusedField,
            isNewGroup: isNewGroup
          )

          SymbolInputView(
            selectedSymbol: $tagGroup.symbolName,
            selectedSymbolValidationStatus: tagGroup.symbolNameValidationStatus,
            focusedField: $focusedField
          )
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif

        Section("add-tag-groups.edit.tags") {
          TagsInputView(
            tags: $tagGroup.tags,
            tagsValidationStatus: tagGroup.tagsValidationStatus,
            focusedField: $focusedField
          )
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }
      .formStyle(.grouped)
      .navigationTitle(
        isNewGroup
          ? "timeline.filter.add-tag-groups"
          : "timeline.filter.edit-tag-groups"
      )
      .navigationBarTitleDisplayMode(.inline)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
        .scrollDismissesKeyboard(.interactively)
      #endif
        .toolbar {
          CancelToolbarItem()
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

  init(tagGroup: TagGroup = .emptyGroup(), onSaved: ((TagGroup) -> Void)? = nil) {
    _tagGroup = State(wrappedValue: tagGroup)
    self.onSaved = onSaved
    isNewGroup = tagGroup.title.isEmpty
  }

  private func save() {
    tagGroup.format()
    context.insert(tagGroup)
    onSaved?(tagGroup)

    dismiss()
  }

  enum Focus {
    case title
    case symbol
    case new
  }
}

struct AddTagGroupView_Previews: PreviewProvider {
  static var previews: some View {
    let container = try? ModelContainer(for: TagGroup.self, configurations: ModelConfiguration())

    // need to use `sheet` to show `symbolsSuggestionView` in preview
    return Text(verbatim: "parent view for EditTagGroupView")
      .sheet(isPresented: .constant(true)) {
        EditTagGroupView()
          .withEnvironments()
          .modelContainer(container!)
      }
  }
}

private struct TitleInputView: View {
  @Binding var title: String
  let titleValidationStatus: TagGroup.TitleValidationStatus

  @FocusState.Binding var focusedField: EditTagGroupView.Focus?

  @Query var tagGroups: [TagGroup]

  let isNewGroup: Bool

  var body: some View {
    VStack(alignment: .leading) {
      TextField("add-tag-groups.edit.title.field", text: $title, axis: .horizontal)
        .focused($focusedField, equals: .title)
        .onSubmit {
          focusedField = .symbol
        }

      if focusedField == .title, warningText != "" {
        Text(warningText).warningLabel()
      }
    }
  }

  var warningText: LocalizedStringKey {
    if case let .invalid(description) = titleValidationStatus {
      return description
    } else if
      isNewGroup,
      tagGroups.contains(where: { $0.title == title })
    {
      return "\(title) add-tag-groups.edit.title.field.warning.already-exists"
    }
    return ""
  }
}

private struct SymbolInputView: View {
  @State private var symbolQuery = ""

  @Binding var selectedSymbol: String
  let selectedSymbolValidationStatus: TagGroup.SymbolNameValidationStatus

  @FocusState.Binding var focusedField: EditTagGroupView.Focus?

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        TextField("add-tag-groups.edit.icon.field", text: $symbolQuery, axis: .horizontal)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .symbol)
          .onSubmit {
            if TagGroup.allSymbols.contains(symbolQuery) {
              selectedSymbol = symbolQuery
            }
            focusedField = .new
          }
          .onChange(of: focusedField) {
            symbolQuery = selectedSymbol
          }

        Image(systemName: selectedSymbol)
          .frame(height: 30)
      }

      if case let .invalid(description) = selectedSymbolValidationStatus,
         focusedField == .symbol
      {
        Text(description).warningLabel()
      }

      if focusedField == .symbol {
        SymbolSearchResultsView(
          symbolQuery: $symbolQuery,
          selectedSymbol: $selectedSymbol,
          focusedField: $focusedField
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 40)
      }
    }
  }
}

private struct TagsInputView: View {
  @State private var newTag: String = ""
  @Binding var tags: [String]
  let tagsValidationStatus: TagGroup.TagsValidationStatus

  @FocusState.Binding var focusedField: EditTagGroupView.Focus?

  var body: some View {
    ForEach(tags, id: \.self) { tag in
      HStack {
        Text(tag)
        Spacer()
        Button { deleteTag(tag) } label: {
          Image(systemName: "trash")
            .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
      }
    }
    .onDelete { indexes in
      if let index = indexes.first {
        let tag = tags[index]
        deleteTag(tag)
      }
    }

    // this `VStack` need to be here to overcome a SwiftUI bug
    // "add new tag" `TextField` is not focused after adding the first tag
    VStack(alignment: .leading) {
      HStack {
        // this condition is using to overcome a SwiftUI bug
        // "add new tag" `TextField` is not focused after adding the first tag
        if tags.isEmpty {
          addNewTagTextField()
        } else {
          addNewTagTextField()
            .onAppear { focusedField = .new }
        }

        Spacer()

        if !newTag.isEmpty, !tags.contains(newTag) {
          Button { addNewTag() } label: {
            Image(systemName: "checkmark.circle.fill").tint(.green)
          }
        }
      }

      if focusedField == .new, warningText != "" {
        Text(warningText).warningLabel()
      }
    }

    var warningText: LocalizedStringKey {
      if tags.contains(newTag) {
        return "add-tag-groups.edit.tags.field.warning.duplicated-tag"
      } else if case let .invalid(description) = tagsValidationStatus {
        return description
      }
      return ""
    }
  }

  private func addNewTagTextField() -> some View {
    VStack(alignment: .leading) {
      TextField("add-tag-groups.edit.tags.add", text: $newTag, axis: .horizontal)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit {
          addNewTag()
        }
        .focused($focusedField, equals: .new)
    }
  }

  private func addNewTag() {
    addTag(newTag.trimmingCharacters(in: .whitespaces).lowercased())
    newTag = ""
    focusedField = .new
  }

  private func addTag(_ tag: String) {
    guard !tag.isEmpty,
          !tags.contains(tag)
    else { return }

    tags.append(tag)
    tags.sort()
  }

  private func deleteTag(_ tag: String) {
    tags.removeAll(where: { $0 == tag })
  }
}

private struct SymbolSearchResultsView: View {
  @Binding var symbolQuery: String
  @Binding var selectedSymbol: String
  @State private var results: [String] = []

  @FocusState.Binding var focusedField: EditTagGroupView.Focus?

  var body: some View {
    Group {
      switch validationStatus {
      case .valid:
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(results, id: \.self) { name in
              Button {
                results = TagGroup.searchSymbol(for: symbolQuery, exclude: selectedSymbol)
                selectedSymbol = name
                symbolQuery = name
                focusedField = .new
              } label: {
                Image(systemName: name)
              }
              .buttonStyle(.plain)
            }
          }
          .animation(.spring(duration: 0.2), value: results)
        }
        .onAppear {
          results = TagGroup.searchSymbol(for: symbolQuery, exclude: selectedSymbol)
        }
      case let .invalid(description):
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .onAppear {
      results = TagGroup.searchSymbol(for: symbolQuery, exclude: selectedSymbol)
    }
    .onChange(of: symbolQuery) {
      results = TagGroup.searchSymbol(for: symbolQuery, exclude: selectedSymbol)
    }
  }

  // MARK: search results validation

  enum ValidationStatus: Equatable {
    case valid
    case invalid(description: LocalizedStringKey)
  }

  var validationStatus: ValidationStatus {
    if results.isEmpty {
      if symbolQuery == selectedSymbol,
         !symbolQuery.isEmpty,
         results.count == 0
      {
        .invalid(description: "\(symbolQuery) add-tag-groups.edit.tags.field.warning.search-results.already-selected")
      } else {
        .invalid(description: "add-tag-groups.edit.tags.field.warning.search-results.no-symbol-found")
      }
    } else {
      .valid
    }
  }
}

extension TagGroup {
  // MARK: title validation

  enum TitleValidationStatus: Equatable {
    case valid
    case invalid(description: LocalizedStringKey)
  }

  var titleValidationStatus: TitleValidationStatus {
    title.isEmpty
      ? .invalid(description: "add-tag-groups.edit.title.field.warning.empty-title")
      : .valid
  }

  // MARK: symbolName validation

  enum SymbolNameValidationStatus: Equatable {
    case valid
    case invalid(description: LocalizedStringKey)
  }

  var symbolNameValidationStatus: SymbolNameValidationStatus {
    if symbolName.isEmpty {
      return .invalid(description: "add-tag-groups.edit.title.field.warning.no-symbol-selected")
    } else if !Self.allSymbols.contains(symbolName) {
      return .invalid(description: "\(symbolName) add-tag-groups.edit.title.field.warning.invalid-sfsymbol-name")
    }

    return .valid
  }

  // MARK: tags validation

  enum TagsValidationStatus: Equatable {
    case valid
    case invalid(description: LocalizedStringKey)
  }

  var tagsValidationStatus: TagsValidationStatus {
    if tags.count < 2 {
      return .invalid(description: "add-tag-groups.edit.tags.field.warning.number-of-tags")
    }
    return .valid
  }

  // MARK: TagGroup validation

  var isValid: Bool {
    titleValidationStatus == .valid
      && symbolNameValidationStatus == .valid
      && tagsValidationStatus == .valid
  }

  // MARK: format

  func format() {
    title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    tags = tags.map { $0.lowercased() }
  }

  // MARK: static members

  static func emptyGroup() -> TagGroup {
    TagGroup(title: "", symbolName: "", tags: [])
  }

  static func searchSymbol(for query: String, exclude excludedSymbol: String) -> [String] {
    guard !query.isEmpty else { return [] }

    return allSymbols.filter {
      $0.contains(query) &&
        $0 != excludedSymbol
    }
  }

  static let allSymbols: [String] = SFSymbol.allSymbols.map { symbol in
    symbol.rawValue
  }
}

extension Text {
  func warningLabel() -> Text {
    font(.caption)
      .foregroundStyle(.red)
  }
}
