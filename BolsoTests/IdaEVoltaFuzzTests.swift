//
//  IdaEVoltaFuzzTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 09/11/26.
//

import Foundation
import Testing
@testable import GastosApp

struct IdaEVoltaFuzzTests {
    @Test(arguments: [1, 2, 3, 4, 5] as [UInt64])
    func idaEVolta(semente: UInt64) {
        var gerador = SplitMix64(semente: semente)
        
        for iteracao in 0..<5000 {
            let centavos = Int.random(in: 0...99_999_999_999)
            let valor = Decimal(centavos) / 100
            
            if valorDeMascara(formatar(valor)) != valor {
                Issue.record("semente \(semente), iteração \(iteracao), valor = \(valor)")
                return
            }
        }
    }
}
