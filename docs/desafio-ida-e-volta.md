# Desafio: teste de ida e volta (round trip)

## A ideia

Duas funções do app são "opostas":

- `formatar(_ valor: Decimal) -> String` — `1234.56` vira `"R$ 1.234,56"`
- `valorDeMascara(_ texto: String) -> Decimal` — `"R$ 1.234,56"` vira `1234.56`

Se uma desfaz a outra, então para **qualquer** valor válido:

```
valorDeMascara(formatar(x)) == x
```

Essa é uma propriedade de ida e volta. Você não precisa saber a resposta
certa de cada caso, só que o resultado volta igual ao que entrou.

## O que fazer

Crie `BolsoTests/IdaEVoltaFuzzTests.swift` com um teste que:

1. use `SplitMix64` com 5 sementes fixas (`@Test(arguments:)`);
2. faça 5.000 iterações por semente;
3. sorteie `centavos` em `0...99_999_999_999` (até 12 dígitos, o limite da máscara);
4. monte o `Decimal` a partir dos centavos (`Decimal(centavos) / 100`);
5. confira `valorDeMascara(formatar(valor)) == valor`;
6. em caso de falha, use `Issue.record` com semente, iteração e valor, e `return`.

## Perguntas para pensar antes de rodar

- Por que o sorteio começa em `0` e não em um número negativo? O que a máscara faz com o sinal de `-`?
- O `formatar` coloca "R$", pontos e um espaço. Por que a máscara ignora tudo isso?
- E se você sortear até `999_999_999_999_999` (15 dígitos)? Prediga o que acontece **antes** de testar.

## Bônus

- Valores de borda forçados: `0`, `0.01`, `0.99`, `1`, `999_999_999.99` (o máximo).
- Teste de sanidade: quebre uma das funções de propósito (por exemplo, `prefix(11)`) e confirme que o teste falha.
- Descubra se o teste falha em alguma máquina com outro idioma configurado. Dica: olhe o `Locale` do formatador.
