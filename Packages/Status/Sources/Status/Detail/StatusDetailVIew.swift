import SwiftUI
import Models
import Shimmer
import Routeur
import Network
import DesignSystem

public struct StatusDetailView: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  @StateObject private var viewModel: StatusDetailViewModel
  @State private var isLoaded: Bool = false
    
  public init(statusId: String) {
    _viewModel = StateObject(wrappedValue: .init(statusId: statusId))
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          switch viewModel.state {
          case .loading:
            ForEach(Status.placeholders()) { status in
              StatusRowView(viewModel: .init(status: status, isEmbed: false))
                .redacted(reason: .placeholder)
                .shimmering()
            }
          case let.display(status, context):
            if !context.ancestors.isEmpty {
              ForEach(context.ancestors) { ancestor in
                StatusRowView(viewModel: .init(status: ancestor, isEmbed: false))
                Divider()
                  .padding(.vertical, DS.Constants.dividerPadding)
              }
            }
            StatusRowView(viewModel: .init(status: status, isEmbed: false))
              .id(status.id)
            Divider()
              .padding(.vertical, DS.Constants.dividerPadding)
            if !context.descendants.isEmpty {
              ForEach(context.descendants) { descendant in
                StatusRowView(viewModel: .init(status: descendant, isEmbed: false))
                Divider()
                  .padding(.vertical, DS.Constants.dividerPadding)
              }
            }
            
          case let .error(error):
            Text(error.localizedDescription)
          }
        }
        .padding(.horizontal, DS.Constants.layoutPadding)
      }
      .task {
        guard !isLoaded else { return }
        isLoaded = true
        viewModel.client = client
        await viewModel.fetchStatusDetail()
        DispatchQueue.main.async {
          proxy.scrollTo(viewModel.statusId, anchor: .center)
        }
      }
    }
    .navigationTitle(viewModel.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
