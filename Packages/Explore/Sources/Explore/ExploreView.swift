import SwiftUI
import Env
import Network
import DesignSystem
import Models
import Status

public struct ExploreView: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel = ExploreViewModel()
  @State private var searchQuery: String = ""
      
  public init() { }
  
  public var body: some View {
    List {
      Section("Trending Tags") {
        ForEach(viewModel.trendingTags
          .prefix(upTo: viewModel.trendingTags.count > 5 ? 5 : viewModel.trendingTags.count)) { tag in
          TagRowView(tag: tag)
            .padding(.vertical, 4)
        }
        NavigationLink {
          List {
            ForEach(viewModel.trendingTags) { tag in
              TagRowView(tag: tag)
                .padding(.vertical, 4)
            }
          }
          .listStyle(.plain)
          .navigationTitle("Trending Tags")
          .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("See more")
            .foregroundColor(.brand)
        }
      }
      
      Section("Trending Posts") {
        ForEach(viewModel.trendingStatuses
          .prefix(upTo: viewModel.trendingStatuses.count > 3 ? 3 : viewModel.trendingStatuses.count)) { status in
          StatusRowView(viewModel: .init(status: status, isEmbed: false))
            .padding(.vertical, 8)
        }
        
        NavigationLink {
          List {
            ForEach(viewModel.trendingStatuses) { status in
              StatusRowView(viewModel: .init(status: status, isEmbed: false))
                .padding(.vertical, 8)
            }
          }
          .listStyle(.plain)
          .navigationTitle("Trending Posts")
          .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("See more")
            .foregroundColor(.brand)
        }
      }
      
      Section("Trending Links") {
        ForEach(viewModel.trendingLinks
          .prefix(upTo: viewModel.trendingLinks.count > 3 ? 3 : viewModel.trendingLinks.count)) { card in
          StatusCardView(card: card)
            .padding(.vertical, 8)
        }
        NavigationLink {
          List {
            ForEach(viewModel.trendingLinks) { card in
              StatusCardView(card: card)
                .padding(.vertical, 8)
            }
          }
          .listStyle(.plain)
          .navigationTitle("Trending Links")
          .navigationBarTitleDisplayMode(.inline)
        } label: {
          Text("See more")
            .foregroundColor(.brand)
        }
      }
    }
    .task {
      viewModel.client = client
      await viewModel.fetchTrending()
    }
    .listStyle(.grouped)
    .navigationTitle("Explore")
    .searchable(text: $searchQuery)
  }
  
}
