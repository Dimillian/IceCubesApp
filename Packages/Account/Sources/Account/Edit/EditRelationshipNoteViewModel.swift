import Network
import SwiftUI

@MainActor
class EditRelationshipNoteViewModel: ObservableObject {
  public var note: String = ""
  public var relatedAccountId: String?
  public var client: Client?

  @Published var isSaving: Bool = false
  @Published var saveError: Bool = false

  init() {}

  func save() async {
    if relatedAccountId != nil,
       client != nil
    {
      isSaving = true
      do {
        let _ = try await client!.post(endpoint: Accounts.relationshipNote(id: relatedAccountId!, json: RelationshipNoteData(note: note)))
      } catch {
        isSaving = false
        saveError = true
      }
    }
  }
}
