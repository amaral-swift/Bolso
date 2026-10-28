//
//  SplitMix64.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 27/10/26.
//

struct SplitMix64: RandomNumberGenerator {
    private var estado: UInt64

    init(semente: UInt64) {
        estado = semente
    }

    mutating func next() -> UInt64 {
        estado &+= 0x9E3779B97F4A7C15
        var z = estado
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
