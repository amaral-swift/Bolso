//
//  SchemaV2.swift
//  GastosApp
//
//  Versão 2 (migração leve): Transacao ganha `recorrente`.
//  Para o treino da etapa 3, Categoria.nome deixa de ser único aqui.
//

import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Transacao.self, Categoria.self] }

    @Model
    class Transacao {
        var titulo: String
        var valor: Decimal
        var data: Date
        var tipo: tipoDeTransacao
        var descricao: String?
        var recorrente: Bool = false

        var categoria: Categoria?

        init(titulo: String, valor: Decimal, descricao: String?, data: Date = .now, tipo: tipoDeTransacao = .gasto, categoria: Categoria? = nil, recorrente: Bool = false) {
            self.titulo = titulo
            self.valor = valor
            self.descricao = descricao
            self.data = data
            self.tipo = tipo
            self.categoria = categoria
            self.recorrente = recorrente
        }
    }

    @Model
    class Categoria {
        var nome: String
        var hexCor: CorRGBA

        @Relationship(deleteRule: .nullify, inverse: \Transacao.categoria)
        var transacoes: [Transacao]? = []

        init(nome: String, hexCor: CorRGBA) {
            self.nome = nome
            self.hexCor = hexCor
        }
    }
}
