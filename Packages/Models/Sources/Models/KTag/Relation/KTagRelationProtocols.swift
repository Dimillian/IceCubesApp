//
//  File.swift
//  
//
//  Created by keisuke koyanagi on 2024/06/15.
//
import Foundation

public protocol IdentifiedDataProtocol:Equatable, Identifiable{
    var id: String { get }
}

public protocol NotIdentifiedKTagAddRelationRequestDataProtocol: Codable, Sendable, Equatable,Hashable{
    var kTagId: String {get}
    var statusId: String {get}
    var isOwned: Bool {get}
    static func == (lhs: Self, rhs: Self) -> Bool
    func hash(into hasher: inout Hasher)
}
extension NotIdentifiedKTagAddRelationRequestDataProtocol {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.kTagId == rhs.kTagId && lhs.statusId == rhs.statusId
    }
    public func hash(into hasher: inout Hasher) {
            hasher.combine(statusId)
            hasher.combine(kTagId)        }

}

public protocol NotIdentifiedKTagAddRelationRequestWithKTagDataProtocol: NotIdentifiedKTagAddRelationRequestDataProtocol{
    var kTag: KTag {get}
}

public protocol NotCreatedYetKTagRelationForSearchAndAddProtocol: NotIdentifiedKTagAddRelationRequestDataProtocol, Codable{
    func encode(to encoder: Encoder) throws
    init(from decoder: Decoder) throws
}

public protocol CreatedKTagRelationWithKTagProtocol:NotIdentifiedKTagAddRelationRequestWithKTagDataProtocol, IdentifiedDataProtocol{
    
}

public protocol CreatedKTagAddRelationRequestDataProtocol: IdentifiedDataProtocol, NotCreatedYetKTagRelationForSearchAndAddProtocol {
}



