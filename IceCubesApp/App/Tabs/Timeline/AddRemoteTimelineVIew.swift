import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import Shimmer
import SwiftUI

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
        TextField("timeline.add.url", text: $instanceName)
          .listRowBackground(theme.primaryBackgroundColor)
          .keyboardType(.URL)
          .textContentType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isInstanceURLFieldFocused)
        if let instance {
          Label("timeline.\(instance.title)-is-valid", systemImage: "checkmark.seal.fill")
            .foregroundColor(.green)
            .listRowBackground(theme.primaryBackgroundColor)
        }
        Button {
          guard instance != nil else { return }
          preferences.remoteLocalTimelines.append(instanceName)
          dismiss()
        } label: {
          Text("timeline.add.action.add")
        }
        .listRowBackground(theme.primaryBackgroundColor)

        instancesListView
      }
      .formStyle(.grouped)
      .navigationTitle("timeline.add-remote.title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel", action: { dismiss() })
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
    Section("instance.suggestions") {
      if instances.isEmpty {
        ProgressView()
          .listRowBackground(theme.primaryBackgroundColor)
      } else {
        ForEach(instanceName.isEmpty ? instances : instances.filter { $0.name.contains(instanceName.lowercased()) }) { instance in
          Button {
            self.instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(instance.name)
                .font(.scaledHeadline)
                .foregroundColor(.primary)
              Text(instance.info?.shortDescription ?? "")
                .font(.scaledBody)
                .foregroundColor(.gray)

              (Text("instance.list.users-\(instance.users)")
                + Text("  ⸱  ")
                + Text("instance.list.posts-\(instance.statuses)"))
                .font(.scaledFootnote)
                .foregroundColor(.gray)
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }
      }
    }
  }
}
