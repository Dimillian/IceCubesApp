//
//  Symbols.swift
//  IceCubesApp
//
//  Created by Alejandro Martinez on 18/7/23.
//

import Foundation


let allSymbols: [String] = {
    if let bundle = Bundle(identifier: "com.apple.CoreGlyphs"),
        let resourcePath = bundle.path(forResource: "symbol_search", ofType: "plist"),
        let plist = NSDictionary(contentsOfFile: resourcePath) {

        return plist.allKeys as? [String] ?? []
    }
    return []
}()
