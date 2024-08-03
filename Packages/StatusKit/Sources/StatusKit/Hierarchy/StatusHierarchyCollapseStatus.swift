import Observation
import Models

@MainActor
@Observable public class StatusHierarchyCollapseState {
    public var explicitlyCollapsedStatusIds: Set<String>
    
    public init(explicitlyCollapsedStatusIds: Set<String> = []) {
        self.explicitlyCollapsedStatusIds = explicitlyCollapsedStatusIds
    }
    
    public func implicitlyCollapsedStatusIds(for statuses: [Status]) -> Set<String> {
        let childs: [String: [String]] = Dictionary(
            grouping: statuses.filter { $0.inReplyToId != nil },
            by: { $0.inReplyToId! }
        ).mapValues { $0.map(\.id) }
        
        func descendants(for id: String) -> [String] {
            (childs[id] ?? []).flatMap { [$0] + descendants(for: $0) }
        }
        
        return Set(explicitlyCollapsedStatusIds.flatMap(descendants(for:)))
    }
}
