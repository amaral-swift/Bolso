//
//  GraficoViewModelTests.swift
//  BolsoTests
//

import Testing
import Foundation
import SwiftData
import SwiftUI
@testable import GastosApp

@MainActor
struct GraficoViewModelTests {
    
    private func data(ano: Int, mes: Int, dia: Int = 15) -> Date {
        Calendar.current.date(from: DateComponents(year: ano, month: mes, day: dia))!
    }
    
    private func criarContexto() throws -> ModelContext {
        let container = try ModelContainer(
            for: Categoria.self, Transacao.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
    
    @Test func transacoesDoMesIgnoraOutrosMeses() {
        let viewModel = GraficoViewModel()
        viewModel.mesSelecionado = data(ano: 2026, mes: 3)
        
        let transacoes = [
            Transacao(titulo: "Março", valor: 10, descricao: nil, data: data(ano: 2026, mes: 3)),
            Transacao(titulo: "Abril", valor: 20, descricao: nil, data: data(ano: 2026, mes: 4)),
            Transacao(titulo: "Março do ano passado", valor: 30, descricao: nil, data: data(ano: 2025, mes: 3))
        ]
        
        let resultado = viewModel.transacoesDoMes(transacoes)
        
        #expect(resultado.map(\.titulo) == ["Março"])
    }
    
    @Test func gastosPorCategoriaAgrupaSomaEOrdenaPeloMaior() throws {
        let context = try criarContexto()
        let viewModel = GraficoViewModel()
        viewModel.mesSelecionado = data(ano: 2026, mes: 3)
        
        let alimentacao = Categoria(nome: "Alimentação", hexCor: Color.blue.toRGBA(), valorTotal: 0)
        let lazer = Categoria(nome: "Lazer", hexCor: Color.yellow.toRGBA(), valorTotal: 0)
        context.insert(alimentacao)
        context.insert(lazer)
        
        let transacoes = [
            Transacao(titulo: "Mercado", valor: 100, descricao: nil, data: data(ano: 2026, mes: 3), tipo: .gasto, categoria: alimentacao),
            Transacao(titulo: "Padaria", valor: 50, descricao: nil, data: data(ano: 2026, mes: 3), tipo: .gasto, categoria: alimentacao),
            Transacao(titulo: "Cinema", valor: 200, descricao: nil, data: data(ano: 2026, mes: 3), tipo: .gasto, categoria: lazer),
            Transacao(titulo: "Salário", valor: 5000, descricao: nil, data: data(ano: 2026, mes: 3), tipo: .receita, categoria: alimentacao)
        ]
        transacoes.forEach { context.insert($0) }
        
        let resultado = viewModel.gastosPorCategoria(transacoes)
        
        #expect(resultado.map(\.categoria.nome) == ["Lazer", "Alimentação"])
        #expect(resultado.map(\.total) == [200, 150])
    }
    
    @Test func mudarMesAvancaEVoltaUmMes() {
        let viewModel = GraficoViewModel()
        viewModel.mesSelecionado = data(ano: 2026, mes: 1)
        
        viewModel.mudarMes(por: -1)
        #expect(Calendar.current.component(.month, from: viewModel.mesSelecionado) == 12)
        #expect(Calendar.current.component(.year, from: viewModel.mesSelecionado) == 2025)
        
        viewModel.mudarMes(por: 1)
        #expect(Calendar.current.component(.month, from: viewModel.mesSelecionado) == 1)
        #expect(Calendar.current.component(.year, from: viewModel.mesSelecionado) == 2026)
    }
    
    @Test func gastosPorCategoria() {
        let viewModel = GraficoViewModel()
        let transacoes = [
            Transacao(titulo: "iFood", valor: 250, descricao: nil, tipo: .gasto, categoria: nil),
            Transacao(titulo: "Carro", valor: 900, descricao: nil, tipo: .gasto, categoria: nil)
        ]
        let resultado = viewModel.gastosPorCategoria(transacoes)
        
        #expect(resultado.isEmpty)
    }
    
    @Test func testSaldoDoMes() {
        let viewModel = GraficoViewModel()
        viewModel.mesSelecionado = data(ano: 2026, mes: 1)
        
        let transacoes = [
            Transacao(titulo: "Salário", valor: 5000, descricao: nil, data: data(ano: 2026, mes: 1), tipo: .receita, categoria: nil),
            Transacao(titulo: "Mercado", valor: 100, descricao: nil, data: data(ano: 2026, mes: 3), tipo: .gasto, categoria: nil),
            Transacao(titulo: "Casa", valor: 2000, descricao: nil, data: data(ano:2026, mes: 1), tipo: .gasto, categoria: nil),
            Transacao(titulo: "Academia", valor: 150, descricao: nil, data: data(ano: 2026, mes: 1), tipo: .gasto, categoria: nil)
        ]
        
        let resultado = viewModel.saldoDoMes(transacoes)
        
        #expect(resultado == 2850)
    }
}
