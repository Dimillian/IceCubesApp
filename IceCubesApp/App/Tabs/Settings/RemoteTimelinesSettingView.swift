import DesignSystem
import Env
import Models
import SwiftData
import SwiftUI

struct RemoteTimelinesSettingView: View {
  @Environment(\.modelContext) private var context

  @Environment(RouterPath.self) private var routerPath
  @Environment(Theme.self) private var theme

  @Query(sort: \LocalTimeline.creationDate, order: .reverse) var localTimelines: [LocalTimeline]

  var body: some View {
    Form {
      ForEach(localTimelines) { timeline in
        Text(timeline.instance)
      }.onDelete { indexes in
        if let index = indexes.first {
          context.delete(localTimelines[index])
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
      Button {
        routerPath.presentedSheet = .addRemoteLocalTimeline
      } label: {
        Label("settings.timeline.add", systemImage: "badge.plus.radiowaves.right")
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.general.remote-timelines")
    .scrollContentBackground(.hidden)
    #if !os(visionOS)
      .background(theme.secondaryBackgroundColor)
    #endif
      .toolbar {
        EditButton()
      }
  }
}
