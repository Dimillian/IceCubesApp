import SwiftUI
import Env

@MainActor
struct NavigationTab<Content: View>: View {
  var content: () -> Content
  
  @State private var routerPath = RouterPath()
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    NavigationStack(path: $routerPath.path) {
      content()
        .withEnvironments()
        .withAppRouter()
        .environment(routerPath)
    }
  }
}
