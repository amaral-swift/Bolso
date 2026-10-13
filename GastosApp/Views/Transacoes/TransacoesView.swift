//
//  LogsView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI
import SwiftData

struct TransacoesView: View {
    @Query(sort: \Categoria.nome, order: .reverse) private var categorias: [Categoria]
    @Query(sort: \Transacao.titulo) private var transacoes: [Transacao]
    @Environment(\.modelContext) private var context
    @State private var mostrarModalAdicionarTransacao: Bool = false
    @State private var categoriaSelecionada: Categoria? = nil
    @State private var categoriaDeletar: Transacao? = nil
    @State private var mostrarConfirmacaoDelecao = false
    @State var transacaoSelecionada: Transacao? = nil
    
    var transacoesFiltradas: [Transacao] {
        if let categoria = categoriaSelecionada {
            return transacoes.filter{ $0.categoria == categoria }
        } else {
            return transacoes
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        Button {
                            categoriaSelecionada = nil
                        } label: {
                            Text("Todas")
                                .padding(.horizontal, 20)
                                .frame(height: 50)
                                .background(.gray.opacity(0.3))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(categorias) { categoria in
                            Button {
                                categoriaSelecionada = categoria
                            } label: {
                                Text(categoria.nome)
                                    .padding(.horizontal, 20)
                                    .frame(height: 50)
                                    .background(categoria.hexCor.color.opacity(0.3))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                Divider()
                NavigationStack {
                    Group {
                        if !transacoes.isEmpty && !transacoesFiltradas.isEmpty{
                            List { // ADICIONAR UM NAVIGATIONLINK PARA A VIEW DOS DETALHES DA TRANSAÇÃO
                                ForEach(transacoesFiltradas.sorted(by: { $1.data < $0.data })) { transacao in
                                    HStack {
                                        Circle()
                                            .fill(corPara(categoria: transacao.categoria, categoriasDaView: categorias))
                                            .frame(width: 10)
                                        Text("\(transacao.titulo) - ")
                                            .font(.title2)
                                            .bold()
                                        if transacao.tipo.rawValue == "Gasto" {
                                            Text(transacao.valor, format: .currency(code: Locale.current.currency?.identifier ?? "BRL"))
                                                .font(.subheadline)
                                                .foregroundStyle(Color.red)
                                        } else {
                                            Text(transacao.valor, format: .currency(code: Locale.current.currency?.identifier ?? "BRL"))
                                                .font(.subheadline)
                                                .foregroundStyle(Color.green)
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            self.categoriaDeletar = transacao
                                            self.mostrarConfirmacaoDelecao = true
                                        } label: {
                                            Label("", systemImage: "trash")
                                        }
                                        Button {
                                            self.transacaoSelecionada = transacao
                                        } label: {
                                            Label("", systemImage: "pencil")
                                        }
                                    }
                                }
                            }
                            .alert("Confimar exclusão", isPresented: $mostrarConfirmacaoDelecao) {
                                Button("Cancelar", role: .cancel) {
                                    categoriaDeletar = nil
                                }
                                Button("Deletar", role: .destructive) {
                                    if let transacao = categoriaDeletar {
                                        context.delete(transacao)
                                    }
                                    categoriaDeletar = nil
                                }
                            } message: {
                                Text("Tem certeza que deseja apagar esta transação? Essa ação não pode ser desfeita.")
                            }
                        } else {
                            ContentUnavailableView("Insira sua primeira transação!", systemImage: "dollarsign.circle", description: Text("Clique no '+' para adicionar"))
                        }
                    }
                    .listStyle(.plain)
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                if categorias.isEmpty {
                    criarCategoriasPadroes(context: context)
                }
            }
            .navigationTitle("Transações")
            .toolbar {
                ToolbarItem {
                    Button("Add", systemImage: "plus") {
                        mostrarModalAdicionarTransacao = true
                    }
                    .sensoryFeedback(.impact, trigger: mostrarModalAdicionarTransacao)
                }
            }
            .sheet(isPresented: $mostrarModalAdicionarTransacao) {
                AdicionarTransacaoView()
            }
            .sheet(item: $transacaoSelecionada) { transacao in
                EditarTransacaoView(transacao: transacao, categorias: categorias)
            }
        }
    }
}
