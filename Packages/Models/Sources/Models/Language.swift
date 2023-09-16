import Foundation

@MainActor
public struct Language: Identifiable, Equatable, Hashable {
  public nonisolated var id: String { isoCode }

  public let isoCode: String
  public let nativeName: String?
  public let localizedName: String?

  public static var allAvailableLanguages: [Language] = Locale.LanguageCode.isoLanguageCodes
    .filter { $0.identifier.count <= 3 }
    .map { lang in
      let nativeLocale = Locale(languageComponents: Locale.Language.Components(languageCode: lang))
      return Language(
        isoCode: lang.identifier,
        nativeName: nativeLocale.localizedString(forLanguageCode: lang.identifier)?.capitalized,
        localizedName: Locale.current.localizedString(forLanguageCode: lang.identifier)?.localizedCapitalized
      )
    }
}

extension Language: Sendable {}
