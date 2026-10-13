//
//  Formatadores.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import Foundation

func formatar(_ valor: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter.string(from: NSNumber(value: valor)) ?? ""
}
