//
//  SwiftDataModels.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftData
import Foundation
import SwiftUI


@Model
class Categoria {
    @Attribute(.unique) var nome: String
    var hexCor: CorRGBA
    var valorTotal: Double
    
    @Relationship(deleteRule: .nullify, inverse: \Transacao.categoria)
    var transacoes: [Transacao]? = []
    
    init(nome: String, hexCor: CorRGBA, valorTotal: Double) {
        self.nome = nome
        self.hexCor = hexCor
        self.valorTotal = valorTotal
    }
}

@Model
class Transacao {
    var titulo: String
    var valor: Double
    var data: Date
    var tipo: tipoDeTransacao
    var descricao: String?
    
    var categoria: Categoria?
    
    init(titulo: String, valor: Double, descricao: String?, data: Date = .now, tipo: tipoDeTransacao = .gasto, categoria: Categoria? = nil) {
        self.titulo = titulo
        self.valor = valor
        self.descricao = descricao
        self.data = data
        self.tipo = tipo
        self.categoria = categoria
    }
}
