//
//  Cores.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI

func corPara(categoria: Categoria?, categoriasDaView: [Categoria]) -> Color {
    guard let categoria = categoria else {
        return .gray
    }

    return categoria.hexCor.color
}

func extrairRGBA(da cor: Color) -> CorRGBA {
    let uiColor = UIColor(cor)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    return CorRGBA(
        red: Double(red),
        green: Double(green),
        blue: Double(blue),
        alpha: Double(alpha)
    )
}
