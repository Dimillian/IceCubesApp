import DesignSystem
import Env
import Models
import Network
import SwiftUI

struct EditFilterView: View {
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var client: Client

  @State private var isSavingFilter: Bool = false
  @State private var filter: ServerFilter?
  @State private var title: String
  @State private var keywords: [ServerFilter.Keyword]
  @State private var newKeyword: String = ""
  @State private var contexts: [ServerFilter.Context]
  @State private var filterAction: ServerFilter.Action

  @FocusState private var isTitleFocused: Bool

  private var data: ServerFilterData {
    .init(title: title,
          context: contexts,
          filterAction: filterAction,
          expireIn: nil)
  }

  private var canSave: Bool {
    !title.isEmpty
  }

  init(filter: ServerFilter?) {
    _filter = .init(initialValue: filter)
    _title = .init(initialValue: filter?.title ?? "")
    _keywords = .init(initialValue: filter?.keywords ?? [])
    _contexts = .init(initialValue: filter?.context ?? [.home])
    _filterAction = .init(initialValue: filter?.filterAction ?? .warn)
  }

  var body: some View {
    Form {
      titleSection
      if filter != nil {
        keywordsSection
        contextsSection
        filterActionView
      }
    }
    .navigationTitle(filter?.title ?? NSLocalizedString("filter.new", comment: ""))
    .navigationBarTitleDisplayMode(.inline)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .onAppear {
      if filter == nil {
        isTitleFocused = true
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        saveButton
      }
    }
  }

  private var titleSection: some View {
    Section("filter.edit.title") {
      TextField("filter.edit.title", text: $title)
        .focused($isTitleFocused)
        .onSubmit {
          Task {
            await saveFilter()
          }
        }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var keywordsSection: some View {
    Section("filter.edit.keywords") {
      ForEach(keywords) { keyword in
        HStack {
          Text(keyword.keyword)
          Spacer()
          Button {
            Task {
              await deleteKeyword(keyword: keyword)
            }
          } label: {
            Image(systemName: "trash")
              .tint(.red)
          }
        }
      }
      .onDelete { indexes in
        if let index = indexes.first {
          let keyword = keywords[index]
          Task {
            await deleteKeyword(keyword: keyword)
          }
        }
      }
      TextField("filter.edit.keywords.add", text: $newKeyword, axis: .horizontal)
        .onSubmit {
          Task {
            await addKeyword(name: newKeyword)
            newKeyword = ""
          }
        }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var contextsSection: some View {
    Section("filter.edit.contexts") {
      ForEach(ServerFilter.Context.allCases, id: \.self) { context in
        Toggle(isOn: .init(get: {
          contexts.contains(where: { $0 == context })
        }, set: { _ in
          if let index = contexts.firstIndex(of: context) {
            contexts.remove(at: index)
          } else {
            contexts.append(context)
          }
          Task {
            await saveFilter()
          }
        })) {
          Label(context.name, systemImage: context.iconName)
        }
        .disabled(isSavingFilter)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var filterActionView: some View {
    Section("filter.edit.action") {
      Picker(selection: $filterAction) {
        ForEach(ServerFilter.Action.allCases, id: \.self) { filter in
          Text(filter.label)
            .id(filter)
        }
      } label: {
        EmptyView()
      }
      .onChange(of: filterAction) { _ in
        Task {
          await saveFilter()
        }
      }
      .pickerStyle(.inline)
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var saveButton: some View {
    Button {
      Task {
        await saveFilter()
        dismiss()
      }
    } label: {
      if isSavingFilter {
        ProgressView()
      } else {
        Text("action.done")
      }
    }
    .disabled(!canSave)
  }

  private func saveFilter() async {
    do {
      isSavingFilter = true
      if let filter {
        self.filter = try await client.put(endpoint: ServerFilters.editFilter(id: filter.id, json: data),
                                           forceVersion: .v2)
      } else {
        let newFilter: ServerFilter = try await client.post(endpoint: ServerFilters.createFilter(json: data),
                                                            forceVersion: .v2)
        filter = newFilter
      }
    } catch {}
    isSavingFilter = false
  }

  private func addKeyword(name: String) async {
    guard let filterId = filter?.id else { return }
    isSavingFilter = true
    do {
      let keyword: ServerFilter.Keyword = try await
        client.post(endpoint: ServerFilters.addKeyword(filter: filterId,
                                                       keyword: name,
                                                       wholeWord: true),
                    forceVersion: .v2)
      keywords.append(keyword)
    } catch {}
    isSavingFilter = false
  }

  private func deleteKeyword(keyword: ServerFilter.Keyword) async {
    isSavingFilter = true
    do {
      let response = try await client.delete(endpoint: ServerFilters.removeKeyword(id: keyword.id),
                                             forceVersion: .v2)
      if response?.statusCode == 200 {
        keywords.removeAll(where: { $0.id == keyword.id })
      }
    } catch {}
    isSavingFilter = false
  }
}
