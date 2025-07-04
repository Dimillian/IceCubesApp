import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
struct EditFilterView: View {
  @Environment(\.dismiss) private var dismiss

  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var account
  @Environment(MastodonClient.self) private var client

  @State private var isSavingFilter: Bool = false
  @State private var filter: ServerFilter?
  @State private var title: String
  @State private var keywords: [ServerFilter.Keyword]
  @State private var newKeyword: String = ""
  @State private var contexts: [ServerFilter.Context]
  @State private var filterAction: ServerFilter.Action
  @State private var expiresAt: Date?
  @State private var expirySelection: Duration

  enum Fields {
    case title, newKeyword
  }

  @FocusState private var focusedField: Fields?

  private var data: ServerFilterData {
    let expiresIn: String? =
      switch expirySelection {
      case .infinite:
        ""  // need to send an empty value in order for the server to clear this field in the filter
      case .custom:
        String(Int(expiresAt?.timeIntervalSince(Date()) ?? 0) + 50)
      default:
        String(expirySelection.rawValue + 50)
      }

    return ServerFilterData(
      title: title,
      context: contexts,
      filterAction: filterAction,
      expiresIn: expiresIn)
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
    _expiresAt = .init(initialValue: filter?.expiresAt?.asDate)
    _expirySelection = .init(initialValue: filter?.expiresAt == nil ? .infinite : .custom)
  }

  var body: some View {
    Form {
      titleSection
      if filter != nil {
        expirySection
        keywordsSection
        contextsSection
        filterActionView
      }
    }
    .navigationTitle(filter?.title ?? NSLocalizedString("filter.new", comment: ""))
    .navigationBarTitleDisplayMode(.inline)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .scrollDismissesKeyboard(.interactively)
      .background(theme.secondaryBackgroundColor)
    #endif
    .onAppear {
      if filter == nil {
        focusedField = .title
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        saveButton
      }
    }
  }

  private var expirySection: some View {
    Section("filter.edit.expiry") {
      Picker(selection: $expirySelection, label: Text("filter.edit.expiry.duration")) {
        ForEach(Duration.filterDurations(), id: \.rawValue) { duration in
          Text(duration.description).tag(duration)
        }
      }
      .onChange(of: expirySelection) { _, newValue in
        if newValue != .custom {
          expiresAt = Date(timeIntervalSinceNow: TimeInterval(newValue.rawValue))
        }
      }
      if expirySelection != .infinite {
        DatePicker(
          "filter.edit.expiry.date-time",
          selection: Binding<Date>(get: { expiresAt ?? Date() }, set: { expiresAt = $0 }),
          displayedComponents: [.date, .hourAndMinute]
        )
        .disabled(expirySelection != .custom)
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var titleSection: some View {
    Section("filter.edit.title") {
      TextField("filter.edit.title", text: $title)
        .focused($focusedField, equals: .title)
        .onSubmit {
          Task {
            await saveFilter(client)
          }
        }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif

    if filter == nil, !title.isEmpty {
      Section {
        Button {
          Task {
            await saveFilter(client)
          }
        } label: {
          if isSavingFilter {
            ProgressView()
              .frame(maxWidth: .infinity)
          } else {
            Text("action.save")
              .frame(maxWidth: .infinity)
          }
        }
        .buttonStyle(.borderedProminent)
        .transition(.opacity)
      }
      #if !os(visionOS)
        .listRowBackground(theme.secondaryBackgroundColor)
      #endif
    }
  }

  private var keywordsSection: some View {
    Section("filter.edit.keywords") {
      ForEach(keywords) { keyword in
        HStack {
          Text(keyword.keyword)
          Spacer()
          Button {
            Task {
              await deleteKeyword(client, keyword: keyword)
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
            await deleteKeyword(client, keyword: keyword)
          }
        }
      }
      HStack {
        TextField("filter.edit.keywords.add", text: $newKeyword, axis: .horizontal)
          .focused($focusedField, equals: .newKeyword)
          .onSubmit {
            Task {
              await addKeyword(client, name: newKeyword)
              newKeyword = ""
              focusedField = .newKeyword
            }
          }
        Spacer()
        if !newKeyword.isEmpty {
          Button {
            Task {
              Task {
                await addKeyword(client, name: newKeyword)
                newKeyword = ""
              }
            }
          } label: {
            Image(systemName: "checkmark.circle.fill")
              .tint(.green)
          }
        }
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var contextsSection: some View {
    Section("filter.edit.contexts") {
      ForEach(ServerFilter.Context.allCases, id: \.self) { context in
        Toggle(
          isOn: .init(
            get: {
              contexts.contains(where: { $0 == context })
            },
            set: { _ in
              if let index = contexts.firstIndex(of: context) {
                contexts.remove(at: index)
              } else {
                contexts.append(context)
              }
              Task {
                await saveFilter(client)
              }
            })
        ) {
          Label(context.name, systemImage: context.iconName)
        }
        .disabled(isSavingFilter)
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
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
      .onChange(of: filterAction) {
        Task {
          await saveFilter(client)
        }
      }
      .pickerStyle(.inline)
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var saveButton: some View {
    Button {
      Task {
        if !newKeyword.isEmpty {
          await addKeyword(client, name: newKeyword)
          newKeyword = ""
          focusedField = .newKeyword
        }
        await saveFilter(client)
        dismiss()
      }
    } label: {
      if isSavingFilter {
        ProgressView()
      } else {
        Text("action.save").bold()
      }
    }
    .disabled(!canSave)
  }

  private func saveFilter(_ client: MastodonClient) async {
    do {
      isSavingFilter = true
      if let filter {
        self.filter = try await client.put(
          endpoint: ServerFilters.editFilter(id: filter.id, json: data),
          forceVersion: .v2)
      } else {
        let newFilter: ServerFilter = try await client.post(
          endpoint: ServerFilters.createFilter(json: data),
          forceVersion: .v2)
        filter = newFilter
      }
    } catch {}
    isSavingFilter = false
  }

  private func addKeyword(_ client: MastodonClient, name: String) async {
    guard let filterId = filter?.id else { return }
    isSavingFilter = true
    do {
      let keyword: ServerFilter.Keyword = try await client.post(
        endpoint: ServerFilters.addKeyword(
          filter: filterId,
          keyword: name,
          wholeWord: true),
        forceVersion: .v2)
      keywords.append(keyword)
    } catch {}
    isSavingFilter = false
  }

  private func deleteKeyword(_ client: MastodonClient, keyword: ServerFilter.Keyword) async {
    isSavingFilter = true
    do {
      let response = try await client.delete(
        endpoint: ServerFilters.removeKeyword(id: keyword.id),
        forceVersion: .v2)
      if response?.statusCode == 200 {
        keywords.removeAll(where: { $0.id == keyword.id })
      }
    } catch {}
    isSavingFilter = false
  }
}
