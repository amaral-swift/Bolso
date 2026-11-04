//
//  CalculosFuzzTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 04/11/26.
//

import Foundation
import Testing
@testable import GastosApp

struct CalculosFuzzTests {
    @Test(arguments: [1, 2, 3, 4, 5] as [UInt64])
    func ordemDaTransacaoNaoMudaTotal(semente: UInt64) {
        var gerador = SplitMix64(semente: semente)
        
        for iteracao in 0..<2_000 {
            let tamanhoLista = Int.random(in: 0...50, using: &gerador)
            var transacoes: [Transacao] = []
            
            for _ in 0..<tamanhoLista {
                let centavos = Int.random(in: 1...999_999, using: &gerador)
                let reais = centavos / 100
                let resto = centavos % 100
                let stringValor = String(format: "%d.%02d", reais, resto)
                let tipoDaTransacao = tipoDeTransacao.allCases.randomElement(using: &gerador)
                let valorEmDecimal = Decimal(string: stringValor)
                
                transacoes.append(Transacao(titulo: "Fuzz", valor: valorEmDecimal!, descricao: nil, tipo: tipoDaTransacao!))
            }
            
            let transacoesEmbaralhadas = transacoes.shuffled(using: &gerador)
            
            let saldoOriginal = calcularValorTotal(transacoes: transacoes)
            let saldoEmbaralhado = calcularValorTotal(transacoes: transacoesEmbaralhadas)
            
            if saldoOriginal != saldoEmbaralhado {
                Issue.record("semente \(semente), iteração \(iteracao): \(saldoOriginal) != \(saldoEmbaralhado)")
                return
            }
        }
    }

}
