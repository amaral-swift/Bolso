//
//  AdicionarCategoria.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 04/03/26.
//

import SwiftUI
import SwiftData

struct AdicionarCategoriaView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var titulo: String = ""
    @State private var hexColor: Color = .black
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Título", text: $titulo)
                ColorPicker("Cor", selection: $hexColor)
            }
            .navigationTitle("Nova Categoria")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        let rgba = extrairRGBA(da: hexColor)
                                            
                        let novaCategoria = Categoria(nome: titulo, hexCor: rgba, valorTotal: 0.0)
                        
                        context.insert(novaCategoria)
                        dismiss()
                    }
                    .disabled(titulo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
