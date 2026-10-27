//
//  Formatadores.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import Foundation

private let formatadorMoeda: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter
}()

func formatar(_ valor: Decimal) -> String {
    formatadorMoeda.string(from: NSDecimalNumber(decimal: valor)) ?? ""
}
