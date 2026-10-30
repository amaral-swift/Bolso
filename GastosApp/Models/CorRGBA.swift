//
//  CorRGBA.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI

struct CorRGBA: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension CorRGBA {
    static let paletaPadraoApple: [CorRGBA] = [
        Color.blue.toRGBA(), Color.green.toRGBA(), Color.orange.toRGBA(), Color.purple.toRGBA(), Color.pink.toRGBA(), Color.yellow.toRGBA(),
        Color.teal.toRGBA(), Color.indigo.toRGBA(), Color.mint.toRGBA(), Color.cyan.toRGBA(), Color.red.toRGBA(), Color.brown.toRGBA()
    ]

    static func corParaCategoria(index: Int) -> CorRGBA {
        let n = paletaPadraoApple.count
        return paletaPadraoApple[((index % n) + n) % n]
    }
}
