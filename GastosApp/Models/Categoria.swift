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

    var valorTotal: Double {
        (transacoes ?? []).reduce(0) { total, transacao in
            transacao.tipo == .receita ? total + transacao.valor : total - transacao.valor
        }
    }

    init(nome: String, hexCor: CorRGBA, valorTotal: Double) {
        self.nome = nome
        self.hexCor = hexCor
    }
}
