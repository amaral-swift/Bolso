//
//  EditarTransacaoView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 05/03/26.
//

import SwiftUI
import SwiftData

struct EditarTransacaoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    var transacao: Transacao
    var categorias: [Categoria]
    
    @State private var tituloTransacao: String = ""
    @State private var valorTransacao: String = "R$ 0,00"
    @State private var tipoDaTransacao: tipoDeTransacao = .gasto
    @State private var dataDaTransacao: Date = Date()
    @State private var categoriaDaTransacao: Categoria?
    @State private var descricaoDaTransacao: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Valor", text: $valorTransacao)
                    .keyboardType(.numberPad)
                    .onChange(of: valorTransacao) { valor, novoValor in
                        let numeros = novoValor.filter { $0.isNumber }
                        let numero = Decimal(string: numeros) ?? 0
                        let valorFinal = numero / 100
                        valorTransacao = formatar(valorDeMascara(novoValor))
                    }
                
                TextField("Título", text: $tituloTransacao)
                
                TextField("Descrição", text: $descricaoDaTransacao)
                
                Picker("Categoria", selection: $categoriaDaTransacao) {
                    Text("Nenhuma")
                        .tag(nil as Categoria?)
                    
                    ForEach(categorias) { categoria in
                        Text(categoria.nome)
                            .tag(categoria as Categoria?)
                    }
                }
                
                DatePicker("Data", selection: $dataDaTransacao, displayedComponents: [.date])
                
                Picker("Tipo", selection: $tipoDaTransacao) {
                    ForEach(tipoDeTransacao.allCases, id: \.self) { tipo in
                        Text(tipo.rawValue)
                            .tag(tipo)
                    }
                }
            }
            .onAppear {
                carregarDadosDaTransacao()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        transacao.titulo = tituloTransacao
                        transacao.valor = valorDeMascara(valorTransacao)
                        transacao.categoria = categoriaDaTransacao
                        transacao.tipo = tipoDaTransacao
                        transacao.descricao = descricaoDaTransacao
                        transacao.data = dataDaTransacao
                        
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Editar")
        }
    }
    
    private func carregarDadosDaTransacao() {
        self.tituloTransacao = transacao.titulo
        self.valorTransacao = formatar(transacao.valor)
        self.categoriaDaTransacao = transacao.categoria
        self.tipoDaTransacao = transacao.tipo
        self.dataDaTransacao = transacao.data
        self.descricaoDaTransacao = transacao.descricao ?? ""
    }
}
