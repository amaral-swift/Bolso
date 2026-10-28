//
//  Mascara.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 27/10/26.
//

import Foundation

private let maximoDeDigitos = 12

func valorDeMascara(_ texto: String) -> Decimal {
    let digitos = texto
        .filter { (48...57).contains($0.asciiValue ?? 0) }
        .prefix(maximoDeDigitos)

    guard let numero = Decimal(string: String(digitos)) else { return 0 }
    return numero / 100
}
