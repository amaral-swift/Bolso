//
//  CategoriasPadraoService.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import SwiftData
import SwiftUI

func criarCategoriasPadroes(context: ModelContext) {
    let padroes = [
        Categoria(nome: "Alimentação", hexCor: Color.blue.toRGBA()),
        Categoria(nome: "Transporte", hexCor: Color.purple.toRGBA()),
        Categoria(nome: "Lazer", hexCor: Color.yellow.toRGBA()),
        Categoria(nome: "Saúde", hexCor: Color.red.toRGBA()),
        Categoria(nome: "Salário", hexCor: Color.green.toRGBA())
    ]

    for categoria in padroes {
        context.insert(categoria)
    }

    try? context.save()
}
