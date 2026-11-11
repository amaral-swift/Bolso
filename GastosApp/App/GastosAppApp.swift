//
//  GastosAppApp.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI
import SwiftData

@main
struct GastosAppApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV3.self),
                migrationPlan: PlanoDeMigracao.self
            )
        } catch {
            fatalError("Não foi possível abrir o banco: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
