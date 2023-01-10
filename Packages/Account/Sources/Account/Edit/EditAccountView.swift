import SwiftUI
import Models
import Network
import DesignSystem

struct EditAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var theme: Theme
  
  @StateObject private var viewModel = EditAccountViewModel()
    
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
      .navigationTitle("Edit Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarContent
      }
      .alert("Error while saving your profile",
             isPresented: $viewModel.saveError,
             actions: {
        Button("Ok", action: { })
      }, message: { Text("Error while saving your profile, please try again.") })
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
    Section("Display Name") {
      TextField("Display Name", text: $viewModel.displayName)
    }
    .listRowBackground(theme.primaryBackgroundColor)
    Section("About") {
      TextField("About", text: $viewModel.note, axis: .vertical)
        .frame(maxHeight: 150)
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private var postSettingsSection: some View {
    Section("Post settings") {
      Picker(selection: $viewModel.postPrivacy) {
        ForEach(Models.Visibility.supportDefault, id: \.rawValue) { privacy in
          Text(privacy.title).tag(privacy)
        }
      } label: {
        Label("Default privacy", systemImage: "lock")
      }
      .pickerStyle(.menu)
      Toggle(isOn: $viewModel.isSensitive) {
        Label("Sensitive content", systemImage: "eye")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private var accountSection: some View {
    Section("Account settings") {
      Toggle(isOn: $viewModel.isLocked) {
        Label("Private", systemImage: "lock")
      }
      Toggle(isOn: $viewModel.isBot) {
        Label("Bot account", systemImage: "laptopcomputer.trianglebadge.exclamationmark")
      }
      Toggle(isOn: $viewModel.isDiscoverable) {
        Label("Discoverable", systemImage: "magnifyingglass")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("Cancel") {
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
          Text("Save")
        }
      }
    }
  }
}
