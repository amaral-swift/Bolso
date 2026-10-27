//
//  Categoria.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftData
import Foundation

@Model
class Categoria {
    @Attribute(.unique) var nome: String
    var hexCor: CorRGBA

    @Relationship(deleteRule: .nullify, inverse: \Transacao.categoria)
    var transacoes: [Transacao]? = []

    var valorTotal: Decimal {
        var total: Decimal = 0
        for transacao in transacoes ?? [] {
            let valor: Decimal = transacao.valor
            if transacao.tipo == .receita {
                total += valor
            } else {
                total -= valor
            }
        }
        return total
    }

    init(nome: String, hexCor: CorRGBA, valorTotal: Double) {
        self.nome = nome
        self.hexCor = hexCor
    }
}
