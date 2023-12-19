import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct EditAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPrefs

  @State private var viewModel = EditAccountViewModel()

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        if viewModel.isLoading {
          loadingSection
        } else {
          aboutSections
          fieldsSection
          postSettingsSection
          accountSection
        }
      }
      .environment(\.editMode, .constant(.active))
      #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      #endif
      .navigationTitle("account.edit.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarContent
      }
      .alert("account.edit.error.save.title",
             isPresented: $viewModel.saveError,
             actions: {
               Button("alert.button.ok", action: {})
             }, message: { Text("account.edit.error.save.message") })
      .task {
        viewModel.client = client
        await viewModel.fetchAccount()
      }
    }
  }

  private var loadingSection: some View {
    Section {
      HStack {
        Spacer()
        ProgressView()
        Spacer()
      }
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var aboutSections: some View {
    Section("account.edit.display-name") {
      TextField("account.edit.display-name", text: $viewModel.displayName)
    }
    .listRowBackground(theme.primaryBackgroundColor)
    Section("account.edit.about") {
      TextField("account.edit.about", text: $viewModel.note, axis: .vertical)
        .frame(maxHeight: 150)
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var postSettingsSection: some View {
    Section("account.edit.post-settings.section-title") {
      if !userPrefs.useInstanceContentSettings {
        Text("account.edit.post-settings.content-settings-reference")
      }
      Picker(selection: $viewModel.postPrivacy) {
        ForEach(Models.Visibility.supportDefault, id: \.rawValue) { privacy in
          Text(privacy.title).tag(privacy)
        }
      } label: {
        Label("account.edit.post-settings.privacy", systemImage: "lock")
      }
      .pickerStyle(.menu)
      Toggle(isOn: $viewModel.isSensitive) {
        Label("account.edit.post-settings.sensitive", systemImage: "eye")
      }
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var accountSection: some View {
    Section("account.edit.account-settings.section-title") {
      Toggle(isOn: $viewModel.isLocked) {
        Label("account.edit.account-settings.private", systemImage: "lock")
      }
      Toggle(isOn: $viewModel.isBot) {
        Label("account.edit.account-settings.bot", systemImage: "laptopcomputer.trianglebadge.exclamationmark")
      }
      Toggle(isOn: $viewModel.isDiscoverable) {
        Label("account.edit.account-settings.discoverable", systemImage: "magnifyingglass")
      }
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var fieldsSection: some View {
    Section("account.edit.metadata-section-title") {
      ForEach($viewModel.fields) { $field in
        VStack(alignment: .leading) {
          TextField("account.edit.metadata-name-placeholder", text: $field.name)
            .font(.scaledHeadline)
          TextField("account.edit.metadata-value-placeholder", text: $field.value)
            .emojiSize(Font.scaledBodyFont.emojiSize)
            .emojiBaselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
            .foregroundColor(theme.tintColor)
        }
      }
      .onMove(perform: { indexSet, newOffset in
        viewModel.fields.move(fromOffsets: indexSet, toOffset: newOffset)
      })
      .onDelete { indexes in
        if let index = indexes.first {
          viewModel.fields.remove(at: index)
        }
      }
      if viewModel.fields.count < 4 {
        Button {
          withAnimation {
            viewModel.fields.append(.init(name: "", value: ""))
          }
        } label: {
          Text("account.edit.add-metadata-button")
            .foregroundColor(theme.tintColor)
        }
      }
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("action.cancel") {
        dismiss()
      }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        Task {
          await viewModel.save()
          dismiss()
        }
      } label: {
        if viewModel.isSaving {
          ProgressView()
        } else {
          Text("action.save").bold()
        }
      }
    }
  }
}
