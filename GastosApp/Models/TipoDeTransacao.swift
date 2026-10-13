//
//  TipoDeTransacao.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import Foundation

enum tipoDeTransacao: String, Codable, CaseIterable {
    case gasto = "Gasto"
    case receita = "Receita"
}
