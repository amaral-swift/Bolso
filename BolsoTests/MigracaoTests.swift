//
//  MigracaoTests.swift
//  BolsoTests
//

import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import GastosApp

@MainActor
struct MigracaoTests {

    private func urlTemporaria() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("migracao-\(UUID().uuidString).store")
    }

    private func abrirNaV3(_ url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: SchemaV3.self),
            migrationPlan: PlanoDeMigracao.self,
            configurations: ModelConfiguration(url: url)
        )
    }

    @Test func dadosDaV1SobrevivemAteAV3() throws {
        let url = urlTemporaria()

        // 1. Cria um banco no formato antigo (V1).
        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV1.self),
                configurations: ModelConfiguration(url: url)
            )
            let context = ModelContext(container)
            let mercado = SchemaV1.Categoria(nome: "Mercado", hexCor: Color.blue.toRGBA())
            context.insert(mercado)
            context.insert(SchemaV1.Transacao(titulo: "Arroz", valor: 20, descricao: nil, tipo: .gasto, categoria: mercado))
            context.insert(SchemaV1.Transacao(titulo: "Feira", valor: 35, descricao: "sábado", tipo: .gasto, categoria: mercado))
            try context.save()
        }

        // 2. Abre com o esquema atual: V1 -> V2 -> V3.
        let container = try abrirNaV3(url)
        let context = ModelContext(container)
        let transacoes = try context.fetch(FetchDescriptor<Transacao>())
        let categorias = try context.fetch(FetchDescriptor<Categoria>())

        #expect(transacoes.count == 2)
        #expect(transacoes.allSatisfy { $0.recorrente == false })
        #expect(Set(transacoes.map(\.titulo)) == ["Arroz", "Feira"])
        #expect(categorias.map(\.nome) == ["Mercado"])
        #expect(transacoes.allSatisfy { $0.categoria?.nome == "Mercado" })
    }

    @Test func categoriasRepetidasNaV2ViramUmaSoNaV3() throws {
        let url = urlTemporaria()

        do {
            let container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV2.self),
                configurations: ModelConfiguration(url: url)
            )
            let context = ModelContext(container)
            let a = SchemaV2.Categoria(nome: "Mercado", hexCor: Color.blue.toRGBA())
            let b = SchemaV2.Categoria(nome: "Mercado", hexCor: Color.red.toRGBA())
            let c = SchemaV2.Categoria(nome: "Lazer", hexCor: Color.green.toRGBA())
            [a, b, c].forEach { context.insert($0) }
            context.insert(SchemaV2.Transacao(titulo: "Arroz", valor: 20, descricao: nil, categoria: a))
            context.insert(SchemaV2.Transacao(titulo: "Feira", valor: 35, descricao: nil, categoria: b))
            context.insert(SchemaV2.Transacao(titulo: "Cinema", valor: 50, descricao: nil, categoria: c))
            try context.save()
        }

        let container = try abrirNaV3(url)
        let context = ModelContext(container)
        let categorias = try context.fetch(FetchDescriptor<Categoria>())
        let mercado = categorias.filter { $0.nome == "Mercado" }

        #expect(categorias.count == 2)
        #expect(mercado.count == 1)
        #expect(Set(mercado[0].transacoes?.map(\.titulo) ?? []) == ["Arroz", "Feira"])
    }
}
