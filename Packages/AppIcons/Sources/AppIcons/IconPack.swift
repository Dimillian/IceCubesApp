//
//  File.swift
//  
//
//  Created by Matt Bonney on 10/16/23.
//

import Foundation

/// Describes a set of alternative app icons, with credit to the artist.
struct IconPack: Identifiable {
    var id: UUID = UUID()
    var title: String
    var icons: [AppIcon]
}

extension IconPack {
    static var allCases: [IconPack] {
        [.official, .albertKinng, .danVanMoll, .chanhwiJoo, .wKovacsAgnes, .duncanHorne, .beAware, .simoneMargio]
    }

    /// App default icon set.
    static let official = IconPack(
        title: "settings.app.icon.official".localized,
        icons: [.primary, .alt1, .alt2, .alt3, .alt4, .alt5, .alt6, .alt7, .alt8, .alt9, .alt10, .alt11, .alt12, .alt13, .alt14, .alt15, .alt16, .alt17, .alt18, .alt19, .alt25]
    )

    /// Extras
    static let albertKinng = IconPack(
        title: "\("settings.app.icon.designed-by".localized) Albert Kinng",
        icons: [.alt20, .alt21, .alt22, .alt23, .alt24]
    )
    static let danVanMoll = IconPack(
        title: "\("settings.app.icon.designed-by".localized) Dan van Moll",
        icons: [.alt26, .alt27, .alt28]
    )
    static let chanhwiJoo = IconPack(
        title: "\("settings.app.icon.designed-by".localized) Chanhwi Joo (GitHub @te6-in)",
        icons: [.alt29, .alt34, .alt31, .alt35, .alt30, .alt32, .alt40]
    )
    static let wKovacsAgnes = IconPack(
        title: "\("settings.app.icon.designed-by".localized) W. Kovács Ágnes (@wildgica)",
        icons: [.alt33]
    )
    static let duncanHorne = IconPack(
        title: "\("settings.app.icon.designed-by".localized) Duncan Horne",
        icons: [.alt36]
    )
    static let beAware = IconPack(
        title: "\("settings.app.icon.designed-by".localized) BeAware@social.beaware.live",
        icons: [.alt37, .alt41, .alt42]
    )
    static let simoneMargio = IconPack(
        title: "\("settings.app.icon.designed-by".localized) Simone Margio",
        icons: [.alt38, .alt39]
    )
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}


