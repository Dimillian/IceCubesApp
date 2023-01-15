import DesignSystem
import Models
import NukeUI
import SwiftUI

struct InstanceInfoView: View {
  @EnvironmentObject private var theme: Theme

  let instance: Instance

  var body: some View {
    Form {
      InstanceInfoSection(instance: instance)
    }
    .navigationTitle("instance.info.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}

public struct InstanceInfoSection: View {
  @EnvironmentObject private var theme: Theme

  let instance: Instance

  public var body: some View {
    Section("instance.info.section.info") {
      LabeledContent("instance.info.name", value: instance.title)
      Text(instance.shortDescription)
      LabeledContent("instance.info.email", value: instance.email)
      LabeledContent("instance.info.version", value: instance.version)
      LabeledContent("instance.info.users", value: "\(instance.stats.userCount)")
      LabeledContent("instance.info.posts", value: "\(instance.stats.statusCount)")
      LabeledContent("instance.info.domains", value: "\(instance.stats.domainCount)")
    }
    .listRowBackground(theme.primaryBackgroundColor)

    if let rules = instance.rules {
      Section("instance.info.section.rules") {
        ForEach(rules) { rule in
          Text(rule.text)
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
}
