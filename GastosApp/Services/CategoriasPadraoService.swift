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
        Categoria(nome: "Alimentação", hexCor: Color.blue.toRGBA(), valorTotal: 0.0),
        Categoria(nome: "Transporte", hexCor: Color.purple.toRGBA(), valorTotal: 0.0),
        Categoria(nome: "Lazer", hexCor: Color.yellow.toRGBA(), valorTotal: 0.0),
        Categoria(nome: "Saúde", hexCor: Color.red.toRGBA(), valorTotal: 0.0),
        Categoria(nome: "Salário", hexCor: Color.green.toRGBA(), valorTotal: 0.0)
    ]

    for categoria in padroes {
        context.insert(categoria)
    }

    try? context.save()
}
