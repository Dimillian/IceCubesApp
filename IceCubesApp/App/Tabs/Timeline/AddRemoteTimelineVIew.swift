import SwiftUI
import Network
import Models
import Env
import DesignSystem
import NukeUI
import Shimmer
import Combine

struct AddRemoteTimelineView: View {
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  
  @State private var instanceName: String = ""
  @State private var instance: Instance?
  @State private var instances: [InstanceSocial] = []

  private let instanceNamePublisher = PassthroughSubject<String, Never>()
  
  @FocusState private var isInstanceURLFieldFocused: Bool
    
  var body: some View {
    NavigationStack {
      Form {
        TextField("Instance URL", text: $instanceName)
          .listRowBackground(theme.primaryBackgroundColor)
          .keyboardType(.URL)
          .textContentType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isInstanceURLFieldFocused)
        if let instance {
          Label("\(instance.title) is a valid instance", systemImage: "checkmark.seal.fill")
            .foregroundColor(.green)
            .listRowBackground(theme.primaryBackgroundColor)
        }
        Button {
          guard instance != nil else { return }
          preferences.remoteLocalTimelines.append(instanceName)
          dismiss()
        } label: {
          Text("Add")
        }
        .listRowBackground(theme.primaryBackgroundColor)
        
        instancesListView
      }
      .formStyle(.grouped)
      .navigationTitle("Add remote local timeline")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { dismiss() })
        }
      }
      .onChange(of: instanceName) { newValue in
        instanceNamePublisher.send(newValue)
      }
      .onReceive(instanceNamePublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { newValue in
        Task {
          let client = Client(server: newValue)
          instance = try? await client.get(endpoint: Instances.instance)
        }
      }
      .onAppear {
        isInstanceURLFieldFocused = true
        let client = InstanceSocialClient()
        Task {
          self.instances = await client.fetchInstances()
        }
      }
    }
  }
  
  private var instancesListView: some View {
    Section("Suggestions") {
      if instances.isEmpty {
        ProgressView()
          .listRowBackground(theme.primaryBackgroundColor)
      } else {
        ForEach(instanceName.isEmpty ? instances : instances.filter{ $0.name.contains(instanceName.lowercased()) }) { instance in
          Button {
            self.instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(instance.name)
                .font(.headline)
                .foregroundColor(.primary)
              Text(instance.info?.shortDescription ?? "")
                .font(.body)
                .foregroundColor(.gray)
              Text("\(instance.users) users  ⸱  \(instance.statuses) posts")
                .font(.footnote)
                .foregroundColor(.gray)
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }
      }
    }
  }
}
