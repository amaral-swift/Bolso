//
//  SchemaV1.swift
//  GastosApp
//
//
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Transacao.self, Categoria.self] }

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

    @Model
    class Categoria {
        @Attribute(.unique) var nome: String
        var hexCor: CorRGBA

        @Relationship(deleteRule: .nullify, inverse: \Transacao.categoria)
        var transacoes: [Transacao]? = []

        init(nome: String, hexCor: CorRGBA) {
            self.nome = nome
            self.hexCor = hexCor
        }
    }
}
