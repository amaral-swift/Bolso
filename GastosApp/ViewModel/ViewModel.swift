//
//  ViewModel.swift
//  GastosApp
//
//  Created by Gabriel Amaral on 18/02/26.
//

import Foundation
import SwiftData
import SwiftUI

struct CorRGBA: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

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

extension CorRGBA {
    static let paletaPadraoApple: [CorRGBA] = [
        Color.blue.toRGBA(), Color.green.toRGBA(), Color.orange.toRGBA(), Color.purple.toRGBA(), Color.pink.toRGBA(), Color.yellow.toRGBA(),
        Color.teal.toRGBA(), Color.indigo.toRGBA(), Color.mint.toRGBA(), Color.cyan.toRGBA(), Color.red.toRGBA(), Color.brown.toRGBA()
    ]
    
    static func corParaCategoria(index: Int) -> CorRGBA {
        return paletaPadraoApple[index % paletaPadraoApple.count]
    }
}

func corPara(categoria: Categoria?, categoriasDaView: [Categoria]) -> Color {
    guard let categoria = categoria else {
        return .gray
    }
    
    return categoria.hexCor.color
}

func calcularValorTotal(transacoes: [Transacao]) -> Double{
    var valorTotal: Double = 0.0
    
    for transacao in transacoes {
        if transacao.tipo == .receita {
            valorTotal += transacao.valor
        } else {
            valorTotal -= transacao.valor
        }
    }
    return valorTotal
}

func formatar(_ valor: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter.string(from: NSNumber(value: valor)) ?? ""
}

func extrairRGBA(da cor: Color) -> CorRGBA {
    let uiColor = UIColor(cor)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    return CorRGBA(
        red: Double(red),
        green: Double(green),
        blue: Double(blue),
        alpha: Double(alpha)
    )
}


extension Color {
    func toRGBA() -> CorRGBA {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return CorRGBA(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            alpha: Double(alpha)
        )
    }
}
