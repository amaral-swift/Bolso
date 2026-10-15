//
//  CoresTests.swift
//  BolsoTests
//
//  Created by Gabriel Amaral on 15/10/26.
//

import Testing
@testable import GastosApp
import SwiftUI

struct CoresTests {

    @Test func testcorPara()  {
        let resultado = corPara(categoria: nil, categoriasDaView: [])
        
        #expect(resultado == .gray)
    }

    @Test func testToRGBA() {
        let resultado = Color.black.toRGBA()
        
        #expect(resultado.red == 0)
        #expect(resultado.green == 0)
        #expect(resultado.blue == 0)
    }
}
