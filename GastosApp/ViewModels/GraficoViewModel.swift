//
//  GraficoViewModel.swift
//  GastosApp
//

import Foundation
import Observation

@Observable
class GraficoViewModel {
    var mesSelecionado: Date = .now

    func transacoesDoMes(_ transacoes: [Transacao]) -> [Transacao] {
        transacoes.filter { transacao in
            Calendar.current.isDate(transacao.data, equalTo: mesSelecionado, toGranularity: .month)
        }
    }

    func gastosPorCategoria(_ transacoes: [Transacao]) -> [(categoria: Categoria, total: Decimal)] {
        var totais: [Categoria: Decimal] = [:]

        for transacao in transacoesDoMes(transacoes) where transacao.tipo == .gasto {
            if let categoria = transacao.categoria {
                totais[categoria, default: 0.0] += transacao.valor
            }
        }

        return totais.map { (categoria: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    func saldoDoMes(_ transacoes: [Transacao]) -> Decimal {
        calcularValorTotal(transacoes: transacoesDoMes(transacoes))
    }

    func mudarMes(por valor: Int) {
        if let novaData = Calendar.current.date(byAdding: .month, value: valor, to: mesSelecionado) {
            mesSelecionado = novaData
        }
    }
}
