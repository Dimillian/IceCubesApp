import Foundation

public protocol KtagProtocol:Identifiable, Codable, Sendable{
    var id: String{get}
    var name: String{get}
    var accountId :String{get}
    static func == (lhs: Self, rhs: Self) -> Bool
}

extension KtagProtocol{
    public static func == (lhs: Self, rhs: Self) -> Bool{
            return lhs.id == rhs.id
        }
}
// タグの検索結果を返す
public struct KTagAddingCandidate :KtagProtocol{
    public let id: String
    public let name: String
    public let accountId :String
}

public struct KTag: KtagProtocol{
    public var accountId: String
    public let id: String
    public let name: String
    public let isOwned: Bool
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accountId = try container.decode(String.self, forKey: .accountId)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.isOwned = try container.decode(Bool.self, forKey: .isOwned)
    }
    
    init(kTagSearchResult: KTagAddingCandidate){
        self.id = kTagSearchResult.id
        self.name = kTagSearchResult.name
        self.isOwned = false // 仮打ち
        self.accountId = kTagSearchResult.accountId
    }
    
    init(id: String, name: String,isOwned: Bool,accountId :String) {
        self.id = id
        self.name = name
        self.isOwned = isOwned
        self.accountId = accountId
    }
}




