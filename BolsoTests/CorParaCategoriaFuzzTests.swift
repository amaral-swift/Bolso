//
//  CorParaCategoriaFuzzTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 29/10/26.
//

import Testing
import Foundation
@testable import GastosApp

struct CorParaCategoriaFuzzTests {

    private static let paleta = CorRGBA.paletaPadraoApple
    private static let tamanho = paleta.count

    // Valores de borda: sorteio quase nunca cai neles, então forçamos.
    private static let valoresPerigosos: [Int] = [
        0, 1, 11, 12, 13,
        -1, -11, -12, -13,
        Int.min, Int.min + 1, Int.max, Int.max - 1
    ]

    // CorRGBA não é Equatable, então comparamos campo a campo.
    private static func iguais(_ a: CorRGBA, _ b: CorRGBA) -> Bool {
        a.red == b.red && a.green == b.green && a.blue == b.blue && a.alpha == b.alpha
    }

    private static func pertenceAPaleta(_ cor: CorRGBA) -> Bool {
        paleta.contains { iguais($0, cor) }
    }

    // i + 12 estoura perto de Int.max; nesses casos usamos i - 12.
    private static func indiceVizinho(_ index: Int) -> Int {
        index <= Int.max - tamanho ? index + tamanho : index - tamanho
    }

    // Regras 1 e 2: não trava e devolve uma cor da paleta.
    // Um @Test por valor: se der crash, o Xcode mostra QUAL valor derrubou.
    @Test(arguments: valoresPerigosos)
    func valorPerigosoDevolveCorDaPaleta(index: Int) {
        let cor = CorRGBA.corParaCategoria(index: index)
        #expect(Self.pertenceAPaleta(cor), "índice \(index) devolveu uma cor fora da paleta")
    }

    // Regra 3: periodicidade (i e i + 12 devolvem a mesma cor).
    @Test(arguments: valoresPerigosos)
    func valorPerigosoEhPeriodico(index: Int) {
        let outro = Self.indiceVizinho(index)
        let a = CorRGBA.corParaCategoria(index: index)
        let b = CorRGBA.corParaCategoria(index: outro)
        #expect(Self.iguais(a, b), "índices \(index) e \(outro) deveriam dar a mesma cor")
    }

    // Fuzzing: números sorteados, com 5 sementes fixas (falha reproduzível).
    @Test(arguments: [1, 2, 3, 4, 5] as [UInt64])
    func indicesAleatoriosRespeitamAsRegras(semente: UInt64) {
        var gerador = SplitMix64(semente: semente)

        for iteracao in 0..<10_000 {
            // Metade perto do zero (onde ficam as bordas), metade no Int inteiro.
            let index = Bool.random(using: &gerador)
                ? Int.random(in: -100...100, using: &gerador)
                : Int.random(in: Int.min...Int.max, using: &gerador)

            let cor = CorRGBA.corParaCategoria(index: index)
            if !Self.pertenceAPaleta(cor) {
                Issue.record("semente \(semente), iteração \(iteracao): índice \(index) devolveu cor fora da paleta")
                return
            }

            let outro = Self.indiceVizinho(index)
            if !Self.iguais(cor, CorRGBA.corParaCategoria(index: outro)) {
                Issue.record("semente \(semente), iteração \(iteracao): índices \(index) e \(outro) deram cores diferentes")
                return
            }
        }
    }
}
