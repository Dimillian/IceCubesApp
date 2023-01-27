import DesignSystem
import Models
import Network
import SwiftUI

public struct EditAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme

  @StateObject private var viewModel = EditAccountViewModel()

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        if viewModel.isLoading {
          loadingSection
        } else {
          aboutSections
          postSettingsSection
          accountSection
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
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
    .listRowBackground(theme.primaryBackgroundColor)
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
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var postSettingsSection: some View {
    Section("account.edit.post-settings.section-title") {
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
    .listRowBackground(theme.primaryBackgroundColor)
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
    .listRowBackground(theme.primaryBackgroundColor)
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
          Text("action.save")
        }
      }
    }
  }
}
