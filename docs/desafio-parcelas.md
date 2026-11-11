# Desafio: dividir uma compra em parcelas

## A ideia

Uma função recebe **dois valores de tipos diferentes** e o libFuzzer só entrega
bytes. Seu trabalho é transformar os bytes nos dois tipos e conferir o resultado
com um oráculo.

## O alvo

Copie para um arquivo novo `Parcelas.swift` no BolsoFuzz:

```swift
import Foundation

/// Divide `total` em `parcelas` parcelas iguais, com 2 casas decimais.
func dividirEmParcelas(total: Decimal, parcelas: Int) -> [Decimal] {
    guard parcelas >= 1 else { return [] }

    var bruto = total / Decimal(parcelas)
    var arredondado = Decimal()
    NSDecimalRound(&arredondado, &bruto, 2, .plain)

    return Array(repeating: arredondado, count: parcelas)
}
```

## O que fazer

1. Crie `Parcelas.swift` com o código acima.
2. No harness, escreva `verificarParcelas(_ bytes:)` e adicione o caso
   `"parcelas"` no `switch` do `fuzz`.
3. Decodifique os bytes assim:

   | Bytes | Tipo | Vira |
   |---|---|---|
   | 0...3 | `UInt32` big-endian | `total` em centavos → `Decimal(centavos) / 100` |
   | 4 | `UInt8` | `parcelas` = `Int(byte) % 24 + 1` (de 1 a 24) |

   Se houver menos de 5 bytes, `return`.
4. Chame `dividirEmParcelas` e confira com `precondition`:
   - a lista tem exatamente `parcelas` elementos;
   - a **soma** das parcelas é igual ao `total` (calcule em centavos, com `Int`);
   - nenhuma parcela é negativa.
5. Rode:

```
ALVO=parcelas ./fuzzer corpus-parcelas -max_total_time=30
```

6. Se achar um crash, siga o guia `docs/lendo-a-saida-do-fuzzer.md`: decodifique
   os bytes à mão (qual era o total? quantas parcelas?) e reproduza com
   `-Onone -g`.

## Perguntas para pensar antes de rodar

- Por que `% 24 + 1` e não só `% 24`? O que aconteceria com `parcelas = 0`?
- Você acha que a função passa em todas as propriedades? Aposte **antes** de rodar.
- Qual é a relação entre "soma das parcelas" e "total"? Ela precisa valer
  para qualquer entrada?

## Bônus

- Conserte a função (dica: pense em onde vão os centavos que sobram) e rode de
  novo o **mesmo** arquivo `crash-*`.
- Acrescente uma propriedade: as parcelas diferem entre si em no máximo 1 centavo.
- Guarde o `crash-*` numa pasta `regressao/`.
