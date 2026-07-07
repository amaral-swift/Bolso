# Bolso

Bolso é um app iOS simples para controle de gastos e receitas pessoais, construído com **SwiftUI** e **SwiftData**.

📱 Disponível na App Store: [Bolso](https://apps.apple.com/br/app/bolso/id6759965476?l=en-GB)

## Funcionalidades

- Registro de transações (gastos e receitas), com título, valor, data e descrição opcional
- Organização das transações por categorias personalizáveis (nome e cor)
- Categorias padrão criadas automaticamente na primeira execução (Alimentação, Transporte, Lazer, Saúde, Salário)
- Visualização gráfica dos gastos por categoria
- Listagem e edição de transações e categorias
- Cálculo automático do saldo total

## Stack

- Swift / SwiftUI
- SwiftData (persistência local)
- Xcode

## Estrutura do projeto

```
GastosApp/
├── GastosAppApp.swift        # Entry point do app
├── Models/                   # Modelos SwiftData (Categoria, Transacao)
├── ViewModel/                 # Lógica auxiliar e formatação
└── View/                      # Telas SwiftUI
    ├── ContentView.swift
    ├── GraficoView.swift
    ├── TransacoesView.swift
    ├── CategoriasView.swift
    ├── AdicionarTransacaoView.swift
    ├── EditarTransacaoView.swift
    ├── AdicionarCategoriaView.swift
    └── EditarCategoriaView.swift
```

## Como rodar

1. Abra `GastosApp.xcodeproj` no Xcode.
2. Selecione um simulador ou dispositivo iOS.
3. Rode o projeto (`Cmd + R`).

## Requisitos

- Xcode mais recente
- iOS 17+ (uso de SwiftData)
