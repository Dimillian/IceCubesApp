import SwiftUI
import Env
import Models
import Shimmer
import Explore
import Env
import Network

struct ExploreTab: View {
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: IceCubesApp.Tab
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      ExploreView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
    }
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .explore {
        routeurPath.path = []
      }
    }
    .onAppear {
      routeurPath.client = client
    }
  }
}
