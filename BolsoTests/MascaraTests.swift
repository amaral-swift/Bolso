//
//  MascaraTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 27/10/26.
//

import Testing
import Foundation
@testable import GastosApp

struct MascaraTests {

    @Test func textoFormatadoViraDecimal() {
        #expect(valorDeMascara("R$ 12,34") == Decimal(string: "12.34")!)
    }

    @Test func textoVazioViraZero() {
        #expect(valorDeMascara("") == 0)
    }

    @Test func milharesSaoIgnorados() {
        #expect(valorDeMascara("R$ 1.234,56") == Decimal(string: "1234.56")!)
    }
    
    @Test func digitoDeOutroAlfabetoNaoCortaOValor() {
        #expect(valorDeMascara("12٣45") == Decimal(string: "12.45")!)
    }

    @Test func maisDeDozeDigitosSaoLimitados() {
        #expect(valorDeMascara("9999999999999") == Decimal(string: "9999999999.99")!)
    }

    @Test func rajadaGigantesNaoGeraLixo() {
        let cem = String(repeating: "7", count: 100)
        #expect(valorDeMascara(cem) == Decimal(string: "7777777777.77")!)
    }
}
