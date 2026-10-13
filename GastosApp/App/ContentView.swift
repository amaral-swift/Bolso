//
//  ContentView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Gráfico", systemImage: "chart.pie") {
                GraficoView()
            }
            Tab("Registros", systemImage: "list.bullet") {
                TransacoesView()
            }
        }
    }
}

#Preview {
    ContentView()
}
