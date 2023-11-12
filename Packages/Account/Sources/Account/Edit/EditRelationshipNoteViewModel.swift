import Network
import Observation
import SwiftUI

@MainActor
@Observable class EditRelationshipNoteViewModel {
  public var note: String = ""
  public var relatedAccountId: String?
  public var client: Client?

  var isSaving: Bool = false
  var saveError: Bool = false

  init() {}

  func save() async {
    if relatedAccountId != nil,
       client != nil
    {
      isSaving = true
      do {
        _ = try await client!.post(endpoint: Accounts.relationshipNote(id: relatedAccountId!, json: RelationshipNoteData(note: note)))
      } catch {
        isSaving = false
        saveError = true
      }
    }
  }
}
