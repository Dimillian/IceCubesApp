//
//  Symbols.swift
//  IceCubesApp
//
//  Created by Alejandro Martinez on 18/7/23.
//

import Foundation
import SFSafeSymbols

let allSymbols: [String] = SFSymbol.allSymbols.map { symbol in
  symbol.rawValue
}
