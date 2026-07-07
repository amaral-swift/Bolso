//
//  AdicionarTransacaoView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftUI
import SwiftData

enum tipoDeTransacao: String, Codable, CaseIterable {
    case gasto = "Gasto"
    case receita = "Receita"
}

struct AdicionarTransacaoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Categoria.nome) private var categorias: [Categoria]
        
    @State private var tituloTransacao: String = ""
    @State private var valorTransacao: String = "R$ 0,00"
    @State private var tipoDaTransacao: tipoDeTransacao = .gasto
    @State private var dataDaTransacao: Date = Date()
    @State private var categoriaDaTransacao: Categoria?
    @State private var descricaoDaTransacao: String = ""
    @State private var feedback: Bool = false
    
    private var valorConvertido: Double {
        let numeros = valorTransacao.filter { $0.isNumber }
        let numero = Double(numeros) ?? 0
        return numero / 100
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Valor", text: $valorTransacao)
                    .keyboardType(.numberPad)
                    .onChange(of: valorTransacao) { valor, novoValor in
                        let numeros = novoValor.filter { $0.isNumber }
                        
                        let numero = Double(numeros) ?? 0
                        let valorFinal = numero / 100
                        
                        valorTransacao = formatar(valorFinal)
                    }
                TextField("Título da transação", text: $tituloTransacao)
                TextField("Descrição (opcional)", text: $descricaoDaTransacao)
                NavigationLink {
                    CategoriasView(categorias: categorias, categoriaDaTransacao: $categoriaDaTransacao)
                } label: {
                    HStack {
                        Text("Categorias")
                        Spacer()
                        Circle()
                            .fill(categoriaDaTransacao?.hexCor.color ?? .gray)
                            .frame(width: 10)
                        Text(categoriaDaTransacao?.nome ?? "Nenhuma")
                    }
                }
                DatePicker(selection: $dataDaTransacao, displayedComponents: [.date]) {
                    Text("Data da transação")
                }
                Picker("Tipo de transação", selection: $tipoDaTransacao) {
                    ForEach(tipoDeTransacao.allCases, id: \.self) { tipo in
                        Text(tipo.rawValue)
                            .tag(tipo)
                    }
                }
            }
            .navigationTitle("Nova Transação")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let novaTransacao = Transacao(titulo: tituloTransacao, valor: valorConvertido, descricao: descricaoDaTransacao, data: dataDaTransacao, tipo: tipoDaTransacao, categoria: categoriaDaTransacao)
                        novaTransacao.categoria?.valorTotal += novaTransacao.valor
                        
                        context.insert(novaTransacao)
                        dismiss()
                    }
                    .disabled(tituloTransacao.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
