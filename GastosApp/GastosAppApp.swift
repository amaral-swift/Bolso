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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Categoria.self, Transacao.self])
    }
}
