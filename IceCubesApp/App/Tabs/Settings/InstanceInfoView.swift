import SwiftUI
import Models
import DesignSystem
import NukeUI

struct InstanceInfoView: View {
  @EnvironmentObject private var theme: Theme
  
  let instance: Instance
  
  var body: some View {
    Form {
      InstanceInfoSection(instance: instance)
    }
    .navigationTitle("Instance Info")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}

public struct InstanceInfoSection: View {
  @EnvironmentObject private var theme: Theme
  
  let instance: Instance
  
  public var body: some View {
    Section("Instance info") {
      LabeledContent("Name", value: instance.title)
      Text(instance.shortDescription)
      LabeledContent("Email", value: instance.email)
      LabeledContent("Version", value: instance.version)
      LabeledContent("Users", value: "\(instance.stats.userCount)")
      LabeledContent("Posts", value: "\(instance.stats.statusCount)")
      LabeledContent("Domains", value: "\(instance.stats.domainCount)")
    }
    .listRowBackground(theme.primaryBackgroundColor)
    
    Section("Instance rules") {
      ForEach(instance.rules) { rule in
        Text(rule.text)
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
}
