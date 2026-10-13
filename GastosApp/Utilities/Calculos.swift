//
//  Calculos.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import Foundation

func calcularValorTotal(transacoes: [Transacao]) -> Double{
    var valorTotal: Double = 0.0

    for transacao in transacoes {
        if transacao.tipo == .receita {
            valorTotal += transacao.valor
        } else {
            valorTotal -= transacao.valor
        }
    }
    return valorTotal
}
