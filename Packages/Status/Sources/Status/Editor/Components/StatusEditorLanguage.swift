import Foundation

struct StatusEditorLanguage: Identifiable, Equatable {
  var id: String { isoCode }

  let isoCode: String
  let nativeName: String?
  let localizedName: String?

  static var allAvailableLanguages: [StatusEditorLanguage] = Locale.LanguageCode.isoLanguageCodes
    .filter { $0.identifier.count == 2 }
    .map { lang in
      let nativeLocale = Locale(languageComponents: Locale.Language.Components(languageCode: lang))
      return StatusEditorLanguage(
        isoCode: lang.identifier,
        nativeName: nativeLocale.localizedString(forLanguageCode: lang.identifier)?.capitalized,
        localizedName: Locale.current.localizedString(forLanguageCode: lang.identifier)?.localizedCapitalized
      )
    }
}
