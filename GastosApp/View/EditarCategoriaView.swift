//
//  EditarCategoriaVIew.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 08/03/26.
//

import SwiftUI
import SwiftData

struct EditarCategoriaView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    var categoriaEditar: Categoria
    var categoria: [Categoria]
    
    @State private var titulo: String = ""
    @State private var hexColor: Color = .black

    var body: some View {
        NavigationStack {
            Form {
                TextField(categoriaEditar.nome, text: $titulo)
                ColorPicker("Cor", selection: $hexColor)
            }
            .navigationTitle("Editar")
            .onAppear {
                carregarDadosCategoria()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        categoriaEditar.nome = titulo
                        categoriaEditar.hexCor = hexColor.toRGBA()
                        
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func carregarDadosCategoria() {
        self.titulo = categoriaEditar.nome
        self.hexColor = categoriaEditar.hexCor.color
    }
}
