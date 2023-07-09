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
  
  @State private var addButtonEnable: Bool = false
  @State private var showProgressView: Bool = false
  @State private var showToast: Bool = false

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
        HStack {
          Button {
            guard instance != nil else { return }
            preferences.remoteLocalTimelines.append(instanceName)
            buttonTappedState()
          } label: {
            Text("timeline.add.action.add")
          }
          .listRowBackground(theme.primaryBackgroundColor)
          .disabled(!addButtonEnable)
          if showProgressView && !instanceName.isEmpty {
            ProgressView()
              .scaleEffect(1.0)
              .padding(.horizontal, 10)
          }
        }
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
        let newValue = newValue.trimmingCharacters(in: .whitespaces)
        formChangedState()
        instanceNamePublisher.send(newValue)
      }
      .onReceive(instanceNamePublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { newValue in
        Task {
          if newValue.isEmpty {
            instance = nil
          } else {
            let client = Client(server: newValue)
            instance = try? await client.get(endpoint: Instances.instance)
          }
          showProgressView = false
          addButtonEnable = (instance != nil) ? true : false
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
    .toast(isShow: $showToast, info: "timeline.add.action.tips")
  }

  private var instancesListView: some View {
    Section("instance.suggestions") {
      if instances.isEmpty {
        ProgressView()
          .listRowBackground(theme.primaryBackgroundColor)
      } else {
        let instanceName = instanceName.trimmingCharacters(in: .whitespaces)
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
        }
      }
    }
  }
  
  private func formChangedState() {
    showProgressView = true
    addButtonEnable = false
  }
  
  private func buttonTappedState() {
    instanceName = ""
    instance = nil
    addButtonEnable = false
    showProgressView = false
    showToast = true
  }
  
  struct TWToastView: View {
    @Binding var isShow: Bool
    let info: LocalizedStringKey
    @State private var isShowAnimation: Bool = true
    @State private var duration : Double
    
    init(isShow: Binding<Bool>, info: LocalizedStringKey, duration: Double = 1.0) {
      self._isShow = isShow
      self.info = info
      self.duration = duration
    }
    
    var body: some View {
      ZStack {
        Text(info)
          .font(.system(size: 12.0))
          .foregroundColor(.white)
          .frame(alignment: Alignment.center)
          .padding(10)
          .zIndex(1.0)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .foregroundColor(.black)
              .opacity(0.6)
          )
      }
      .onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          isShowAnimation = false
        }
      }
      .frame(alignment: .bottom)
      .opacity(isShowAnimation ? 1 : 0)
      .edgesIgnoringSafeArea(.all)
      .onChange(of: isShowAnimation) { e in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.isShow = false
        }
      }
    }
  }
}

extension View {
  func toast(isShow: Binding<Bool>, info: String = "", _duration: Double = 1.0) -> some View {
    ZStack(alignment: .bottom) {
      self
      if isShow.wrappedValue {
        AddRemoteTimelineView.TWToastView(isShow:isShow, info: LocalizedStringKey(info), duration: _duration)
      }
    }
  }
}
