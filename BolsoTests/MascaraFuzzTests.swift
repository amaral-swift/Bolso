//
//  MascaraFuzzTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 27/10/26.
//

import Testing
import Foundation
@testable import GastosApp

struct MascaraFuzzTests {
    
    private static let alfabeto: [String] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "R$", " ", ".", ",", "-", "+",
        "²", "½", "٣", "１", "🙂", "\n", "a", "\u{0301}"
    ]
    
    private static func gerarEntrada(_ gerador: inout SplitMix64) -> String {
        var texto = ""
        
        if Int.random(in: 0..<5, using: &gerador) == 0 {
            let tamanho = Int.random(in: 30...120, using: &gerador)
            for _ in 0..<tamanho {
                texto += String(Int.random(in: 0...9, using: &gerador))
            }
            return texto
        }
        
        let tamanho = Int.random(in: 0...80, using: &gerador)
        for _ in 0..<tamanho {
            texto += alfabeto.randomElement(using: &gerador)!
        }
        return texto
    }
    
    private static let teto = Decimal(string: "9999999999.99")!
    private static let maxDigitos = 12
    
    private static func violacoes(para entrada: String) -> [String] {
        var problemas: [String] = []
        let valor = valorDeMascara(entrada)
        
        if valor.isNaN { problemas.append("P1: virou NaN") }
        if valor < 0 { problemas.append("P2: ficou negativo (\(valor))") }
        
        var multiplicado = valor * 100
        var arredondado = Decimal()
        NSDecimalRound(&arredondado, &multiplicado, 0, .plain)
        if arredondado != multiplicado { problemas.append("P3: mais de 2 casas decimais (\(valor))") }
        
        if valor > teto { problemas.append("P4: acima do teto (\(valor))") }
        
        let digitos = entrada
            .filter { (48...57).contains($0.asciiValue ?? 0) }
            .prefix(maxDigitos)
        let esperado = Decimal(Int(String(digitos)) ?? 0) / 100
        if valor != esperado { problemas.append("P5: esperado \(esperado), obtido \(valor)") }
        
        return problemas
    }
    
    @Test(arguments: [1, 2, 3, 4, 5] as [UInt64])
    func valorDeMascaraRespeitaAsPropriedades(semente: UInt64) {
        var gerador = SplitMix64(semente: semente)
        
        for _ in 0..<10_000 {
            let entrada = Self.gerarEntrada(&gerador)
            let problemas = Self.violacoes(para: entrada)
            
            if !problemas.isEmpty {
                Issue.record("semente \(semente), entrada \(entrada.debugDescription): \(problemas.joined(separator: " | "))")
                return
            }
        }
    }
}
