//
//  CategoriasView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 06/03/26.
//

import SwiftUI
import SwiftData

struct CategoriasView: View {
    var categorias: [Categoria]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @Binding var categoriaDaTransacao: Categoria?
    @State private var categoriaTemporaria: Categoria?
    @State private var mostrarAlerta: Bool = false
    @State private var categoriaEditar: Categoria?
    
    var body: some View {
        NavigationStack {
            Form {
                Button {
                    categoriaTemporaria = nil
                } label: {
                    HStack {
                        Circle()
                            .fill(.gray)
                            .frame(width: 10)
                        Text("Nenhuma")
                        Spacer()
                        if categoriaTemporaria == nil {
                            Image(systemName: "checkmark")
                                .padding(.horizontal)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                ForEach(categorias) { categoria in
                    Button {
                        categoriaTemporaria = categoria
                    } label: {
                        HStack {
                            Circle()
                                .fill(categoria.hexCor.color)
                                .frame(width: 10)
                            Text(categoria.nome)
                            Spacer()
                            if categoriaTemporaria?.nome == categoria.nome {
                                Image(systemName: "checkmark")
                                    .padding(.horizontal)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .contextMenu {
                        Button {
                            self.categoriaEditar = categoria
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            self.categoriaEditar = categoria
                            self.mostrarAlerta = true
                        } label: {
                            Label("Deletar", systemImage: "trash")
                        }
                    }
                    .buttonStyle(.plain)
                }
                .alert("Confimar exclusão", isPresented: $mostrarAlerta) {
                    Button("Cancelar", role: .cancel) {
                        categoriaTemporaria = nil
                    }
                    Button("Deletar", role: .destructive) {
                        if let categoria = categoriaTemporaria {
                            context.delete(categoria)
                        }
                        categoriaTemporaria = nil
                    }
                } message: {
                    Text("Tem certeza que deseja apagar esta transação? Essa ação não pode ser desfeita.")
                }
                
                NavigationLink() {
                    AdicionarCategoriaView()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Adicionar categoria")
                    }
                }
            }
            .navigationTitle("Categorias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        categoriaDaTransacao = categoriaTemporaria
                        dismiss()
                    } label: {
                        Text("Salvar")
                    }
                }
            }
            .sheet(item: $categoriaEditar) { categoria in
                EditarCategoriaView(categoriaEditar: categoria, categoria: categorias)
            }
        }
    }
}
