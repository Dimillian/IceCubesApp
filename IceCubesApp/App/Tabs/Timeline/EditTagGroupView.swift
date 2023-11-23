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
  @Bindable private var tagGroup: TagGroup
  @Bindable private var symbolSearchModel = TagGroup.SymbolSearchModel()
  @State private var symbolQuery = ""

  private let onSaved: ((TagGroup) -> Void)?
  private let isNewGroup: Bool

  @FocusState private var focusedField: Focus?

  enum Focus {
    case title
    case symbol
    case new
  }

  init(tagGroup: TagGroup = .emptyGroup, onSaved: ((TagGroup) -> Void)? = nil) {
    self._tagGroup = Bindable(wrappedValue: tagGroup)
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
      TextField("add-tag-groups.edit.title.field", text: $tagGroup.title, axis: .horizontal)
        .focused($focusedField, equals: Focus.title)
        .onSubmit {
          focusedField = Focus.symbol
        }

      VStack {
        HStack {
          TextField("add-tag-groups.edit.icon.field", text: $symbolQuery, axis: .horizontal)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: Focus.symbol)
            .onSubmit {
              if TagGroup.SymbolSearchModel.allSymbols.contains(symbolQuery) {
                tagGroup.symbolName = symbolQuery
              }
              focusedField = Focus.new
            }
            .onChange(of: symbolQuery) {
              symbolSearchModel.search(for: symbolQuery, exclude: tagGroup.symbolName)
            }
            .onChange(of: focusedField) {
              symbolQuery = tagGroup.symbolName
            }

            Image(systemName: tagGroup.symbolName)
            .frame(height: 30)
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

  private func addNewTagTextField() -> some View {
    return TextField("add-tag-groups.edit.tags.add", text: $newTag, axis: .horizontal)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .onSubmit {
        addNewTag()
      }
      .focused($focusedField, equals: Focus.new)
  }

  private func addNewTag() {
    addTag(newTag.trimmingCharacters(in: .whitespaces).lowercased())
    newTag = ""
    focusedField = Focus.new
  }

  // TODO: Show error and disable <Enter> for empty and duplicate tags
  private func addTag(_ tag: String) {
    guard !tag.isEmpty else { return }
    tagGroup.tags.append(tag)
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
    if symbolSearchModel.results.isEmpty {
      Text("No Symbol Found")
    } else if symbolQuery == tagGroup.symbolName && symbolSearchModel.results.count == 1 {
      Text("\(symbolQuery)").bold().italic() + Text(" are already selected.")
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(symbolSearchModel.results, id: \.self) { symbolName in
            Button {
              symbolSearchModel.search(for: symbolQuery, exclude: symbolName)
              tagGroup.symbolName = symbolName
            } label: {
              Image(systemName: symbolName)
            }
            .buttonStyle(.plain)
          }
        }
        .animation(.spring(duration: 0.2), value: symbolSearchModel.results)
      }
      .onAppear {
        symbolSearchModel.search(for: symbolQuery, exclude: tagGroup.symbolName)
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
  static let emptyGroup = TagGroup(title: "", symbolName: "", tags: [])

  var isValid: Bool {
    !title.isEmpty &&
    tags.count >= 2 // At least have 2 tags, one main and one additional.
  }

  func format() {
    title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    tags = tags.map { $0.lowercased() }
  }

  @Observable
  final class SymbolSearchModel: Sendable {
    private var currentQuery = ""
    private(set) var results: [String] = []

    private var task = Task<Void, Never> {}
    func search(for query: String, exclude excludedSymbol: String) {
      task.cancel()
      currentQuery = query

      guard !query.isEmpty
      else {
        results = []
        return
      }

      task = Task {
        guard !Task.isCancelled,
              query == self.currentQuery
        else { return }

        results = Self.allSymbols.filter {
          $0.contains(query) &&
          $0 != excludedSymbol
        }
      }
    }

    deinit { task.cancel() }

    static let allSymbols: [String] = SFSymbol.allSymbols.map { symbol in
      symbol.rawValue
    }
  }
}
