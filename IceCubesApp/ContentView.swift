import SwiftUI
import Network

struct ContentView: View {
  @State private var statuses: [Status] = []
  @State private var client = Client(server: "mastodon.social")
  
  var body: some View {
    List(statuses) { status in
      VStack(alignment: .leading) {
        HStack {
          AsyncImage(
            url: status.account.avatar,
            content: { image in
              image.resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(13)
                .frame(maxWidth: 26, maxHeight: 26)
            },
            placeholder: {
              ProgressView()
            }
          )
          Text(status.account.username)
        }
        Text(status.content)
      }
    }
    .task {
      do {
        self.statuses = try await client.fetchArray(endpoint: Timeline.pub)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
