//
//  Transacao.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftData
import Foundation

@Model
class Transacao {
    var titulo: String
    var valor: Decimal
    var data: Date
    var tipo: tipoDeTransacao
    var descricao: String?

    var categoria: Categoria?

    init(titulo: String, valor: Decimal, descricao: String?, data: Date = .now, tipo: tipoDeTransacao = .gasto, categoria: Categoria? = nil) {
        self.titulo = titulo
        self.valor = valor
        self.descricao = descricao
        self.data = data
        self.tipo = tipo
        self.categoria = categoria
    }
}
