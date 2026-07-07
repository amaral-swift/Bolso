//
//  DashboardView.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 28/02/26.
//

import SwiftUI
import Charts
import SwiftData

struct GraficoView: View {
    @Query(sort: \Categoria.nome, order: .reverse) private var categorias: [Categoria]
    @Query(sort: \Transacao.valor, order: .forward) private var transacoes: [Transacao]
    
    @State private var mesSelecionado: Date = .now
    
    var transacoesPorMes: [Transacao] {
        transacoes.filter { transacao in
            Calendar.current.isDate(transacao.data, equalTo: mesSelecionado, toGranularity: .month)
        }
    }
    
    var gastosPorCategoria: [(categoria: Categoria, total: Double)] {
        var totais: [Categoria: Double] = [:]
        
        for transacao in transacoesPorMes where transacao.tipo == .gasto {
            if let categoria = transacao.categoria {
                totais[categoria, default: 0.0] += transacao.valor
            }
        }
        
        return totais.map { (categoria: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
    
    private var categoriaComMaiorGasto: (categoria: Categoria, total: Double)? {
        gastosPorCategoria.first
    }
    
    private var valorTotalGasto: Double {
        calcularValorTotal(transacoes: transacoesPorMes)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: { mudarMes(por: -1) }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(mesSelecionado.formatted(.dateTime.month(.wide).year()))
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button(action: { mudarMes(por: 1) }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.horizontal)

                Chart(gastosPorCategoria, id: \.categoria.nome) { item in
                    if item.total > 0 {
                        SectorMark(
                            angle: .value("Gasto", item.total),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Categoria", item.categoria.nome))
                    }
                }
                .chartForegroundStyleScale(
                    domain: categorias.map { $0.nome },
                    range: categorias.map { $0.hexCor.color }
                )
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        let frame = geometry[chartProxy.plotFrame!]
                        VStack {
                            if let maior = categoriaComMaiorGasto, maior.total > 0 {
                                Text("Maior gasto")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                Text(maior.categoria.nome)
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                                
                                Text(maior.total, format: .currency(code: "BRL"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ContentUnavailableView("Sem gastos esse mês", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", description: Text("Adicione um registro"))
                            }
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                    
                }
                .animation(.snappy(duration: 0.5), value: mesSelecionado)
                .chartLegend(spacing: 20)
                .frame(maxHeight: .infinity)
                .padding()
                
                HStack {
                    Text("Resumo mensal: ")
                        .font(.title2)
                        .bold()
                    if valorTotalGasto < 0 {
                        Text(valorTotalGasto, format: .currency(code: "BRL"))
                            .font(.title2)
                            .foregroundStyle(Color.red)
                            .bold()
                    } else if valorTotalGasto == 0 {
                        Text(valorTotalGasto, format: .currency(code: "BRL"))
                            .font(.title2)
                            .bold()
                    } else {
                        Text(valorTotalGasto, format: .currency(code: "BRL"))
                            .font(.title2)
                            .foregroundStyle(Color.green)
                            .bold()
                    }
                }
                .padding()
            }
            .padding(UIDevice.current.userInterfaceIdiom == .pad ? 60 : 0)
            .navigationTitle("Gráfico")
        }
    }
    
    private func mudarMes(por valor: Int) {
        if let novaData = Calendar.current.date(byAdding: .month, value: valor, to: mesSelecionado) {
            mesSelecionado = novaData
        }
    }
}

#Preview {
    GraficoView()
}
