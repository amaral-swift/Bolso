# Passo a passo: teste de fuzzing para a máscara de moeda do Bolso

> **Objetivo:** criar um teste de fuzzing para a função que converte o texto digitado no campo "Valor" (por exemplo `R$ 12,34`) em um `Decimal`. No fim há um desafio para você fazer sozinho.

## O que foi verificado e o que não foi

Antes de começar, o que eu testei de fato e o que não testei:

- **Testei:** escrevi o gerador, as propriedades e o teste exatamente como estão neste guia, em um pacote Swift isolado (SwiftPM) no macOS, com o Swift Testing. Contra a versão atual da função, o teste **falha** nas 5 sementes. Contra a versão corrigida (Passo 11), ele **passa**. Os números e as mensagens de erro citados abaixo vieram dessas execuções.
- **Não testei:** rodar dentro do target `BolsoTests` do Xcode, em um simulador. Nesta máquina o simulador era iOS 18.6 e o app exige iOS 26, então não consegui rodar lá. O código é o mesmo, mas os caminhos (`@testable import GastosApp`) são os do seu projeto e eu não executei neles. Se algo não compilar, o erro mais provável está nos `import`.
- **Não testei:** as telas rodando no app.

---

## Parte 1 — A ideia

### Passo 1. O que é fuzzing

Um teste normal diz: "para esta entrada, espero esta saída".

```
valorDeMascara("R$ 12,34")  →  espero 12.34
```

Ele só verifica as entradas que **você** pensou. O problema é que bugs vivem justamente nas entradas que você não pensou.

Fuzzing inverte a lógica: o computador **gera milhares de entradas estranhas** e você diz **o que precisa ser sempre verdade**, para qualquer entrada. Essas regras se chamam **propriedades**. Exemplos:

- "o resultado nunca é negativo";
- "o resultado nunca passa de R$ 9.999.999.999,99";
- "o programa nunca trava".

Se alguma entrada quebrar uma propriedade, o teste falha e mostra qual entrada foi.

**Uma observação importante sobre o nome.** O fuzzing "de verdade" usa ferramentas como libFuzzer, que observam o código e evoluem as entradas sozinhas. O Swift Testing não tem isso. O que vamos fazer aqui é fuzzing **por propriedades com entradas aleatórias reproduzíveis**, que é a versão que cabe em um teste unitário normal. Os mesmos conceitos valem nas duas.

### Passo 2. Escolher o alvo e justificar a escolha

Um bom alvo de fuzzing tem estas características:

1. **Recebe uma entrada que você não controla.** Aqui, o texto do campo de valor. O usuário pode digitar, colar e apagar qualquer coisa.
2. **É uma função pura**: mesma entrada, mesma saída, sem banco de dados e sem tela.
3. **Errar custa caro.** Aqui, o valor errado vai para o saldo do usuário.
4. **Tem lógica que parece simples e esconde detalhes.** Esse é o caso: `filter`, `isNumber`, `Decimal(string:)`.

A lógica hoje está duplicada dentro das duas telas. No `AdicionarTransacaoView.swift` e no `EditarTransacaoView.swift` aparece este trecho:

```swift
let numeros = valorTransacao.filter { $0.isNumber }
let numero = Decimal(string: numeros) ?? 0
return numero / 100
```

Ela funciona assim: o usuário digita só números, e o app trata os dois últimos dígitos como centavos. Digitar `1`, `2`, `3`, `4` mostra `R$ 12,34`.

Outros candidatos que existem no projeto, para você saber por que não escolhi eles:

| Candidato | Por que não |
|---|---|
| `calcularValorTotal` | Entrada já é um array de objetos. Ótimo para o desafio bônus, mas menos "hostil". |
| `formatar` | Recebe `Decimal`, não texto livre. Menos superfície de ataque. |
| `corParaCategoria(index:)` | Vai ser o seu desafio. |

---

## Parte 2 — Preparar o terreno

### Passo 3. Extrair a lógica para uma função pura

**O que fazer.** Crie o arquivo `GastosApp/Utilities/Mascara.swift`:

```swift
import Foundation

func valorDeMascara(_ texto: String) -> Decimal {
    let numeros = texto.filter { $0.isNumber }
    let numero = Decimal(string: numeros) ?? 0
    return numero / 100
}
```

Repare que ainda é **exatamente o código atual**, só que movido para um lugar onde dá para chamar sem abrir uma tela.

**Por que fazer isso.** Não dá para testar um trecho que está dentro de um `var valorConvertido` de uma `View`. Para testar, a lógica precisa ter um nome, receber uma entrada e devolver uma saída. Essa mudança também elimina a duplicação entre as duas telas.

**Por que ainda não corrigir nada.** Se você corrigir antes de testar, nunca vai saber se o teste teria encontrado o problema. Queremos ver o fuzzer **falhar** primeiro (isso se chama "ver o teste vermelho").

> Neste passo, não mude as telas ainda. Isso vem no Passo 12.

### Passo 4. Um teste de exemplo como ponto de partida

Crie `BolsoTests/MascaraTests.swift`:

```swift
import Testing
import Foundation
@testable import GastosApp

struct MascaraTests {

    @Test func textoFormatadoViraDecimal() {
        #expect(valorDeMascara("R$ 12,34") == Decimal(string: "12.34")!)
    }

    @Test func textoVazioViraZero() {
        #expect(valorDeMascara("") == 0)
    }

    @Test func milharesSaoIgnorados() {
        #expect(valorDeMascara("R$ 1.234,56") == Decimal(string: "1234.56")!)
    }
}
```

**Por que fazer.** Esses testes provam duas coisas: que o alvo é chamável do target de testes (o `@testable import` funciona) e que o caminho "normal" está certo. Se eles não passarem, o problema é de configuração, e não do fuzzing.

**Por que `Decimal(string: "12.34")!` em vez de `12.34`?** Um literal como `12.34` passa por `Double` antes de virar `Decimal`, e isso reintroduz o problema de ponto flutuante que conversamos. Criar a partir de texto evita isso.

Rode com **⌘U** e confirme que os 3 passam antes de continuar.

---

## Parte 3 — Construir o fuzzer

Um fuzzer tem três peças: um **gerador de números aleatórios que dá para repetir**, um **gerador de entradas** e as **propriedades**.

### Passo 5. Gerador pseudoaleatório com semente

**O que fazer.** Crie `BolsoTests/Suporte/SplitMix64.swift`:

```swift
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
```

**Por que não usar o gerador padrão do Swift** (`Int.random(in:)` sem mais nada)? Porque o padrão é imprevisível: cada execução usa números diferentes. Se o teste falhar hoje e passar amanhã, você nunca vai conseguir investigar. Com uma **semente** fixa, a mesma semente gera sempre a mesma sequência. Quando o teste falhar, o relatório diz "semente 3" e você consegue reproduzir a falha quantas vezes quiser.

**O que é cada linha.** O `SplitMix64` é um algoritmo clássico e pequeno de geração de números. O protocolo `RandomNumberGenerator` exige só o método `next()`. O `&+=` e o `&*` são operações que "dão a volta" no estouro em vez de travar, porque aqui o estouro é esperado e faz parte da matemática do algoritmo. Você não precisa decorar os números mágicos. O importante é o comportamento: mesma semente, mesma sequência.

### Passo 6. Gerador de entradas "hostis"

**O que fazer.** Crie `BolsoTests/MascaraFuzzTests.swift` e comece com o alfabeto e o gerador:

```swift
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
}
```

**Por que um alfabeto escolhido à mão em vez de caracteres totalmente aleatórios?** Texto aleatório puro quase nunca produz algo parecido com um valor de moeda. Quase todas as entradas seriam lixo que a função descarta sem problema, e você testaria pouco. O alfabeto mistura:

- **Dígitos, duas vezes cada.** Eles aparecem com frequência, para a entrada parecer um número de verdade.
- **O que o usuário realmente digita:** `R$`, espaço, ponto, vírgula, sinal de menos.
- **O que parece número mas não é um dígito comum:**
  - `²` (expoente), `½` (fração), `٣` (dígito arábico), `１` (dígito de largura total). Todos retornam `true` em `isNumber`. Esse é o palpite que originou todo este exercício: o filtro atual usa `isNumber`, e `isNumber` é mais amplo do que "0 a 9".
- **Casos esquisitos de Unicode:** emoji, quebra de linha, a letra `a` e um acento solto (`\u{0301}`), que se cola no caractere anterior e forma um único "caractere" para o Swift.

**Por que o segundo bloco, a "rajada de dígitos"?** Em 1 de cada 5 entradas, o gerador cria só dígitos, entre 30 e 120 deles. Na minha primeira versão não havia isso, e o fuzzer não encontrou o problema de números gigantes, porque uma string de até 80 caracteres misturados quase nunca tem 39 dígitos seguidos. **Um fuzzer só acha o que o gerador é capaz de produzir.** Ajustar o gerador depois de ver o que ele não alcança é parte normal do trabalho.

**Detalhe de Swift.** O parâmetro é `inout` porque gerar um número muda o estado interno do gerador. Todas as funções `random(..., using: &gerador)` recebem o `&`.

### Passo 7. Escrever as propriedades

Esta é a parte mais importante. Pergunte-se: **"o que precisa ser verdade para QUALQUER texto?"** Eu escolhi cinco:

| # | Propriedade | Por que importa |
|---|---|---|
| P1 | O resultado não é `NaN` | `NaN` ("não é um número") contamina qualquer soma que o inclua. |
| P2 | O resultado não é negativo | O campo só aceita dígitos. O sinal de menos é ignorado, e o tipo (gasto/receita) decide o sinal. |
| P3 | No máximo 2 casas decimais | Dinheiro tem centavos. 12,345 seria inválido. |
| P4 | Não passa de R$ 9.999.999.999,99 | Define um teto razoável. Veja a decisão abaixo. |
| P5 | É igual ao que se calcula "à mão" | O oráculo. Veja abaixo. |

**A decisão do teto (P4).** Escolhi 12 dígitos, ou seja, R$ 9.999.999.999,99. Isso é uma **decisão minha de produto**, não uma verdade matemática. Ninguém registra uma despesa de dez bilhões, e um teto evita o problema que vamos ver no Passo 9. Se você preferir outro número, mude as duas constantes (`teto` e `maxDigitos`). O fuzzer não sabe o que é um bug: ele só sabe o que **você** disse que deveria ser verdade.

**O oráculo (P5).** Um "oráculo" é uma segunda forma, independente, de calcular a resposta certa. Aqui ele é: pegue só os dígitos ASCII (0 a 9), limite aos 12 primeiros, converta com `Int(...)` e divida por 100. Eu uso `Int` em vez de `Decimal(string:)` de propósito: se o oráculo usasse o mesmo mecanismo da função, os dois errariam juntos e a comparação não provaria nada.

Adicione dentro da struct:

```swift
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
```

**Explicando as partes difíceis:**

- **Como testar "no máximo 2 casas" (P3)?** Multiplico o valor por 100 e arredondo para inteiro com `NSDecimalRound`. Se o arredondado for diferente do multiplicado, havia casas sobrando. Exemplo: `12.345 × 100 = 1234.5`, que arredonda para `1235`, diferente, então viola.
- **Por que `asciiValue` e não `("0"..."9").contains`?** A segunda forma parece certa, mas compara pela ordem do Unicode. Um dígito com acento (`1` + `\u{0301}`) fica "entre" `"0"` e `"9"` nessa ordem e passa no filtro. Eu cometi esse erro na primeira versão do oráculo, e o próprio fuzzer apontou. `asciiValue` devolve o código ASCII só quando o caractere é exatamente um caractere ASCII, e 48 a 57 são os códigos de `0` a `9`.
- **Por que a função devolve uma lista de problemas em vez de usar `#expect` direto?** Porque dentro de um laço de 10.000 iterações, queremos montar uma mensagem com a semente e a entrada que falhou. Veja o próximo passo.

### Passo 8. O teste que junta tudo

```swift
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
```

**Por que `arguments:` com 5 sementes?** O Swift Testing roda o mesmo teste uma vez por semente, e cada uma aparece como um caso separado no relatório. Cinco sementes com 10.000 entradas cada dão 50.000 entradas no total. Você pode aumentar a lista ou o número de iterações. Mais entradas encontram mais problemas, mas o teste fica mais lento (aqui levou cerca de 0,25 segundo).

**Por que `Issue.record` e `return` em vez de `#expect`?** `#expect` registra uma falha e **continua**. Num laço de 10.000 passos, uma entrada ruim poderia gerar milhares de falhas iguais. `Issue.record(...)` com `return` registra a **primeira** falha com uma mensagem útil e para.

**Por que `debugDescription` na entrada?** Ele mostra caracteres invisíveis como escapes (`\n`, `\u{0301}`). Sem isso, você veria uma string aparentemente normal que não consegue copiar.

---

## Parte 4 — Rodar, ler e corrigir

### Passo 9. Rodar e ver o teste vermelho

Rode com **⌘U**. Na versão atual da função, **os 5 casos falham**. No meu ambiente, as mensagens foram assim (cortei o meio da entrada):

```
semente 1, entrada "\u{0301}55+１79²3R$5845 ½,🙂2264917-1́R$934888+½.１-8.１٣15…":
  P5: esperado 5579358452.26, obtido 0.55
```

**Como ler essa mensagem.** A entrada começa com `55`, segue um `+`, depois um `１` (dígito de largura total) e depois mais números. A função devolveu `0.55`, ignorando todo o resto. O motivo: `isNumber` deixa o `１` passar pelo `filter`, mas `Decimal(string:)` **para de ler** assim que encontra algo que não é um dígito ASCII. O número foi **cortado no meio**, sem aviso.

Isso é um comportamento real e silencioso: `"12٣45"` (com um dígito arábico no meio) vira `0,12`, e não `12,45`.

Num experimento separado, também vi o segundo problema:

| Entrada | Resultado atual |
|---|---|
| 38 dígitos `9` | `999999999999999999999999999999999999.99` (correto) |
| 39 dígitos `9` | `9999999999999999999999999999999999999.9` (já perdeu um dígito) |
| 60 dígitos `9` | `9999999999999999999999999999999999999900000000000000000000` (lixo) |
| 100 dígitos `7` | um número com uns 98 dígitos, terminado em zeros |

`Decimal` guarda cerca de 38 dígitos significativos. Passando disso, ele **não dá erro**: arredonda e completa com zeros. Resultado: um valor errado, enorme, salvo sem ninguém perceber.

### Passo 10. Separar "bug" de "decisão de especificação"

Nem toda falha do fuzzer é um bug. Analise cada tipo:

- **P4 e P5 com mais de 12 dígitos** (por exemplo, `0288322198947`, que a função atual converte para `2883221989.47`): isso não está "errado" matematicamente. É a decisão do teto. Eu decidi limitar a 12 dígitos para impedir os números gigantes. A falha aqui é um **desacordo com a especificação que eu defini**.
- **Corte no meio do número** (`12٣45` virando `0,12`): isso é bug de verdade. O usuário não esperava perder dígitos.
- **Mais de 38 dígitos virando lixo**: bug de verdade.

Em um projeto real, você deve decidir isso **antes** de corrigir. Pergunte: "o comportamento atual é o que eu queria?". Se for, mude a propriedade, e não o código.

### Passo 11. Corrigir

Troque o conteúdo de `Utilities/Mascara.swift`:

```swift
import Foundation

private let maximoDeDigitos = 12

func valorDeMascara(_ texto: String) -> Decimal {
    let digitos = texto
        .filter { (48...57).contains($0.asciiValue ?? 0) }
        .prefix(maximoDeDigitos)

    guard let numero = Decimal(string: String(digitos)) else { return 0 }
    return numero / 100
}
```

**O que mudou e por quê:**

1. **`isNumber` virou "só dígitos ASCII 0 a 9".** Assim, o que passa pelo filtro é exatamente o que `Decimal(string:)` consegue ler, e nada é cortado no meio.
2. **`.prefix(12)`.** Limita a 12 dígitos. Qualquer dígito além disso é ignorado. Na tela, isso significa que o campo para de aceitar números novos ao chegar no teto.
3. **`guard let` em vez de `?? 0`.** Faz a mesma coisa, mas deixa claro que "não consegui ler" é um caso tratado, e não um detalhe escondido.

**Decisão que você deve conhecer:** dígitos de outros alfabetos (`٣`, `１`) agora são **ignorados**, e não convertidos. Converter seria possível, mas a máscara é alimentada pelo teclado numérico, que só produz 0 a 9. Ignorar é o comportamento mais simples e previsível.

### Passo 12. Rodar de novo e ver o teste verde

Rode **⌘U**. No meu ambiente, passaram os 5 casos (50.000 entradas) em cerca de 0,25 segundo.

Agora conecte a função nas telas, para elas usarem a versão corrigida. Em `AdicionarTransacaoView.swift` e `EditarTransacaoView.swift`:

- `valorConvertido` passa a ser só `valorDeMascara(valorTransacao)`.
- O corpo do `onChange` passa a ser `valorTransacao = formatar(valorDeMascara(novoValor))`.

**Um ponto de atenção que encontrei lendo o código.** No `AdicionarTransacaoView.swift`, o `onChange` ainda converte por `Double`:

```swift
let numero = Double(numeros) ?? 0
let valorFinal = numero / 100
valorTransacao = formatar(Decimal(valorFinal))
```

Isso reintroduz o problema de ponto flutuante. No mesmo experimento, `"R$ 1.234.567,89"` passando por `Double` virou `1234567.8899999997952`, e `"123456789012345678"` virou `...56.7168` em vez de `...56.78`. O `EditarTransacaoView.swift` já usa `Decimal` nesse trecho. Usar `valorDeMascara` nas duas telas resolve a diferença. Depois da mudança, rode o app e digite valores no campo, porque eu não rodei as telas.

### Passo 13. Guardar o que o fuzzer achou como testes fixos

Fuzzers dependem de sorte e de semente. Um bug encontrado hoje pode não aparecer se você mudar o gerador amanhã. Por isso, **cada entrada que o fuzzer achar vira um teste normal**, no `MascaraTests.swift`:

```swift
    @Test func digitoDeOutroAlfabetoNaoCortaOValor() {
        #expect(valorDeMascara("12٣45") == Decimal(string: "12.45")!)
    }

    @Test func maisDeDozeDigitosSaoLimitados() {
        #expect(valorDeMascara("9999999999999") == Decimal(string: "9999999999.99")!)
    }

    @Test func rajadaGigantesNaoGeraLixo() {
        let cem = String(repeating: "7", count: 100)
        #expect(valorDeMascara(cem) == Decimal(string: "7777777777.77")!)
    }
```

Os valores esperados acima eu conferi rodando a função corrigida. Esses testes são rápidos, legíveis e explicam **por que** a função tem o `prefix`. Quem ler daqui a seis meses entende. Esse conjunto de entradas se chama **corpus de regressão**.

---

## Parte 5 — Limites e próximos passos

- **Cobertura de entradas.** 50.000 entradas é pouco perto do universo possível. Quanto mais variado for o alfabeto e o gerador, mais problemas você acha. Se a execução ficar lenta, deixe o fuzzing longo para rodar só em CI ou em um plano de teste separado.
- **Falsa sensação de segurança.** Fuzzing que passa não prova que não há bugs. Prova que não achou bugs **nas propriedades que você escreveu**, com **as entradas que seu gerador cria**. Se você esquecer uma propriedade importante, nada avisa.
- **O que falta nesta função.** O fuzzer não testa que o `formatar` e a máscara se conversam bem. Uma boa propriedade extra seria o ciclo completo: `valorDeMascara(formatar(x)) == x` para qualquer `x` válido. Isso está relacionado ao desafio abaixo.
- **Fuzzing de verdade.** Para ir além, procure por libFuzzer e `-sanitize=fuzzer` no Swift. É um assunto à parte.

---

## Desafio para você fazer sozinho

### Alvo: `CorRGBA.corParaCategoria(index:)`

Está em `GastosApp/Models/CorRGBA.swift`. Ela recebe um número e devolve uma cor da paleta de 12 cores, voltando ao início quando o número passa de 11.

### O que fazer

1. **Crie** `BolsoTests/CorParaCategoriaFuzzTests.swift`.
2. **Decida as propriedades** antes de escrever qualquer código. Escreva em um papel, em português, o que precisa ser verdade para qualquer número inteiro. Sugestões para você pensar:
   - o programa não trava;
   - o resultado sempre pertence à paleta;
   - a função é **periódica**: o índice `i` e o índice `i + 12` devolvem a mesma cor.
3. **Use o `SplitMix64`** que já existe. Não copie o gerador de entradas da máscara: você precisa criar o seu, para **números inteiros**.
4. **Pense nas entradas de borda.** Fuzzing aleatório quase nunca sorteia `0`, `-1`, `12` ou os extremos do `Int`. Misture aleatórios com uma lista fixa de valores "perigosos" que você escolher. Pense em: zero, um, o tamanho da paleta, números negativos, o menor e o maior `Int`.
5. **Rode e leia o resultado com atenção.**

### Uma pista, sem entregar a resposta

Em Swift, o operador `%` com número negativo se comporta diferente do que muita gente espera. Eu conferi: `-1 % 12` dá `-1`, e `Int.min % 12` dá `-8`. Pense no que acontece quando esse resultado é usado como posição em um array.

Importante: se a falha for uma **queda do programa** (e não uma falha de `#expect`), o Xcode vai mostrar o teste interrompido, sem aquela mensagem bonita com a semente. Isso também é uma lição: um *crash* é o pior resultado de um fuzzer, e é por isso que ele existe. Para investigar, rode um valor por vez até achar o que derruba.

### Perguntas que o seu resultado deve responder

- Alguém **chama** a função com índice negativo hoje? Procure no projeto de onde vem o `index`. Se nunca acontece, a correção é desnecessária?
- Se você decidir corrigir, qual é o comportamento certo para `-1`: a última cor da paleta, a primeira, ou um erro? Isso é decisão sua, e a propriedade do teste deve refletir a escolha.
- Depois da correção, o teste fica verde? Transforme cada valor perigoso que você achou em um teste fixo, como no Passo 13.

### Desafio bônus

Escreva um teste de propriedade para `calcularValorTotal`:

- **Propriedade:** a ordem das transações **não pode** mudar o saldo. Embaralhe a lista com o seu gerador (`shuffled(using:)`) e compare os dois saldos com `==`, sem tolerância.
- Gere valores aleatórios com centavos (por exemplo, de `0.01` a `9999.99`), criados a partir de **texto** para evitar `Double`.
- **Pergunta final:** o que aconteceria com esse teste se `Transacao.valor` ainda fosse `Double`? Se tiver tempo, troque temporariamente para `Double` num pacote de testes à parte, rode e compare. Esse é o jeito mais convincente de ver, na prática, o que conversamos sobre ponto flutuante.

Boa sorte!
