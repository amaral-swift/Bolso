//
//  Schemas.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 11/11/26.
//

import Foundation
import SwiftData

enum PlanoDeMigracao: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrarV1paraV2, migrarV2paraV3]
    }

    static let migrarV1paraV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )


    static let migrarV2paraV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            let categorias = try context.fetch(FetchDescriptor<SchemaV2.Categoria>())
            var primeiraPorNome: [String: SchemaV2.Categoria] = [:]

            for categoria in categorias {
                if let primeira = primeiraPorNome[categoria.nome] {
                    for transacao in categoria.transacoes ?? [] {
                        transacao.categoria = primeira
                    }
                    context.delete(categoria)
                } else {
                    primeiraPorNome[categoria.nome] = categoria
                }
            }
            try context.save()
        },
        didMigrate: nil
    )
}
