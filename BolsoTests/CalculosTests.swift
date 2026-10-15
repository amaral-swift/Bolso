//
//  CalculosTests.swift
//  BolsoTests
//

import Testing
import Foundation
@testable import GastosApp

struct CalculosTests {

    @Test func listaVaziaRetornaZero() {
        #expect(calcularValorTotal(transacoes: []) == 0)
    }

    @Test func receitaSomaEGastoSubtrai() {
        let transacoes = [
            Transacao(titulo: "Salário", valor: 1000, descricao: nil, tipo: .receita),
            Transacao(titulo: "Mercado", valor: 300, descricao: nil, tipo: .gasto),
            Transacao(titulo: "Cinema", valor: 50, descricao: nil, tipo: .gasto)
        ]

        #expect(calcularValorTotal(transacoes: transacoes) == 650)
    }

    @Test func saldoNegativoQuandoGastosSuperamReceitas() {
        let transacoes = [
            Transacao(titulo: "Freela", valor: 100, descricao: nil, tipo: .receita),
            Transacao(titulo: "Aluguel", valor: 400, descricao: nil, tipo: .gasto)
        ]

        #expect(calcularValorTotal(transacoes: transacoes) == -300)
    }
}
