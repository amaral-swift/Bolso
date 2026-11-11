# Lendo a saída do libFuzzer quando ele acha um erro

Este guia usa uma saída **real**, gerada com o alvo `soma` depois da mutação
"receita também subtrai" em `Soma.swift`.

---

## 1. A ideia em uma frase

Quando o fuzzer acha um erro, ele faz três coisas:

1. **Para** o programa (o crash).
2. **Mostra onde** o programa parou (a pilha de chamadas).
3. **Salva a entrada** que causou o crash em um arquivo `crash-...`.

Para entender o erro, o arquivo `crash-...` importa mais do que o texto na tela.

---

## 2. A saída completa, dividida em partes

### Parte A: o fuzzer trabalhando (antes do crash)

```
INFO: Seed: 1
INFO: A corpus is not provided, starting from an empty corpus
#2	INITED cov: 34 ft: 34 corp: 1/1b exec/s: 0 rss: 42Mb
#3	NEW    cov: 34 ft: 35 corp: 2/2b lim: 4 exec/s: 0 rss: 42Mb L: 1/1 MS: 1 ShuffleBytes-
#20	NEW    cov: 34 ft: 37 corp: 4/5b lim: 4 exec/s: 0 rss: 42Mb L: 2/2 MS: 4 CopyPart-...
```

| Campo | Significado |
|---|---|
| `Seed` | Número que inicia o sorteio. Mesma seed, mesma sequência de tentativas |
| `#20` | Número da tentativa (a 20ª execução) |
| `NEW` | Esta entrada fez o código passar por um lugar novo, então foi guardada |
| `cov` | Quantos "pontos" do código já foram visitados |
| `ft` | Quantos *comportamentos* diferentes já foram vistos (mais fino que `cov`) |
| `corp: 4/5b` | Corpus: 4 entradas guardadas, 5 bytes no total |
| `lim` | Tamanho máximo que o fuzzer está tentando agora |
| `exec/s` | Execuções por segundo |
| `L: 2/2` | Tamanho (em bytes) da entrada que gerou esta linha |
| `MS: 4 CopyPart-...` | **M**utation **S**equence: quais mutações foram aplicadas para chegar nela |

Dica: se `cov` e `ft` param de subir, o fuzzer não está achando caminhos novos.

### Parte B: o crash

```
==7225== ERROR: libFuzzer: deadly signal
```

"Deadly signal" quer dizer: **o programa morreu**. No Swift, isso acontece
quando o código **trava de propósito** (`precondition` falhou, índice fora do
array, divisão por zero, overflow de inteiro, `!` em `nil`...).

Não quer dizer que algo "explodiu" no sistema. É o Swift dizendo "isso nunca
deveria acontecer, vou parar".

### Parte C: a pilha de chamadas (stack trace)

```
#4 ... in verificarSoma(_:)+0x488 (fuzzer:arm64+0x100006be4)
#5 ... in fuzz(_:_:)+0x5f4
#6 ... in LLVMFuzzerTestOneInput+0x18
#7 ... in fuzzer::Fuzzer::ExecuteCallback(...)
```

Leia **de baixo para cima** como "quem chamou quem", ou **de cima para baixo**
como "onde parou, e por quem foi chamado".

- `#0` a `#3`: o próprio libFuzzer e o sistema tratando o sinal. **Ignore.**
- `#4`: **a primeira linha que é código seu**. Aqui, `verificarSoma`. É onde o
  programa morreu.
- `#5`, `#6`: quem chamou `verificarSoma` (seu harness).
- `#7` em diante: o motor do libFuzzer. **Ignore.**

Regra prática: procure a **primeira função com nome seu** na lista.

### Parte D: o resumo e a entrada culpada

```
SUMMARY: libFuzzer: deadly signal
MS: 4 CrossOver-InsertByte-EraseBytes-InsertRepeatedBytes-; base unit: 8768a53e...
0x0,0x0,0x0,0xa,0xcc,
\000\000\000\012\314
artifact_prefix='.../'; Test unit written to .../crash-3b2587992705b967547cc4c9461afa86f1f17d11
Base64: AAAACsw=
```

Esta é **a parte mais importante**. Quatro jeitos de ver a mesma entrada:

| Linha | O que é |
|---|---|
| `0x0,0x0,0x0,0xa,0xcc,` | Os bytes em hexadecimal, no formato de um array para colar em código |
| `\000\000\000\012\314` | Os mesmos bytes, em octal |
| `Base64: AAAACsw=` | Os mesmos bytes, em texto compacto |
| `Test unit written to .../crash-3b25...` | **Arquivo** com esses bytes. É o seu "bilhete de reprodução" |

`MS:` mostra as mutações que produziram essa entrada, e `base unit` é a entrada
guardada de onde ela partiu. São curiosidades, e normalmente não precisam de
atenção.

---

## 3. O problema: "o que esses bytes significam?"

Os bytes `00 00 00 0a cc` são só números. Quem dá sentido a eles é o
**decodificador** (`Decodificador.swift`). Lembre do formato: **5 bytes por
transação**.

```
byte 0       -> tipo   (par = receita, ímpar = gasto)
bytes 1..4   -> centavos (UInt32, big-endian)
```

Decodificando `00 00 00 0a cc` à mão:

| Parte | Bytes | Conta | Resultado |
|---|---|---|---|
| tipo | `00` | 0 é par | **receita** |
| centavos | `00 00 0a cc` | `0x0acc` = 10×256 + 204 | **2764 centavos** = **R$ 27,64** |

Ou seja: **uma única transação, uma receita de R$ 27,64**. O fuzzer achou que a
menor entrada que quebra a soma é "uma receita só".

Isso faz sentido com a mutação: se receita estiver subtraindo, o resultado dá
`-27,64` em vez de `27,64`.

---

## 4. Como descobrir o que quebrou, passo a passo

### Passo 1: reproduza o crash, sem fuzzing

Passe o arquivo `crash-...` como argumento. O fuzzer roda **só aquela entrada,
uma vez**:

```
ALVO=soma ./fuzzer crash-3b2587992705b967547cc4c9461afa86f1f17d11
```

### Passo 2: recompile **sem** `-O` para ver a mensagem

Com `-O` (otimizado), o Swift **remove o texto** do `precondition`. Você vê só
"deadly signal" e nada mais. Foi o que aconteceu na saída da seção 2.

Para ver o motivo, compile uma versão de depuração (`-Onone -g`):

```
~/Library/Developer/Toolchains/swift-6.4.2-RELEASE.xctoolchain/usr/bin/swiftc \
  -sdk "$(xcrun --show-sdk-path)" -parse-as-library \
  -sanitize=fuzzer,address -Onone -g \
  Alvo.swift Soma.swift Decodificador.swift Harness.swift -o fuzzer-debug

ALVO=soma ./fuzzer-debug crash-3b2587992705b967547cc4c9461afa86f1f17d11
```

Agora a saída traz a mensagem que você escreveu no harness e o número da linha:

```
main/Harness.swift:20: Precondition failed: soma errada: obtido -27.64, esperado 27.64, com 1 transações
...
#5 ... in verificarSoma(_:) Harness.swift:20
#6 ... in fuzz(_:_:) Harness.swift:41
```

Leia assim:

| Pedaço | Significado |
|---|---|
| `Harness.swift:20` | A linha do `precondition` que falhou |
| `obtido -27.64` | O que **o alvo** (`calcularValorTotal`) devolveu |
| `esperado 27.64` | O que **o oráculo** (soma em centavos) calculou |
| `com 1 transações` | A entrada tinha 1 transação |

**Diagnóstico:** o alvo e o oráculo discordam, e o sinal está invertido.
Então o bug está em como `calcularValorTotal` trata o sinal de **receita**.

### Passo 3: olhe o alvo com a entrada em mãos

Abra `Soma.swift` e "execute de cabeça" a entrada: uma receita de 27,64.

```swift
if transacao.tipo == .receita {
    valorTotal -= transacao.valor   // <-- era para ser +=
}
```

Entrada: receita de 27,64 → `valorTotal = 0 - 27.64 = -27.64`. Bate com o
"obtido" da mensagem. Achamos o bug.

### Passo 4 (opcional): inspecionar no depurador

Se não for óbvio, use `lldb`:

```
lldb -- ./fuzzer-debug crash-3b2587992705b967547cc4c9461afa86f1f17d11
(lldb) run
(lldb) bt          # pilha de chamadas
(lldb) frame select 5
(lldb) frame variable
```

### Passo 5: conserte e rode de novo o **mesmo arquivo**

Depois de corrigir (`-=` virou `+=`), **recompile** e rode o mesmo arquivo:

```
ALVO=soma ./fuzzer crash-3b2587992705b967547cc4c9461afa86f1f17d11
```

Se terminar sem erro, a correção funciona para essa entrada. Depois rode o
fuzzing de novo para ver se ele acha outro problema.

### Passo 6: guarde o arquivo como teste de regressão

Copie o `crash-...` para uma pasta (por exemplo `regressao/`) e rode-a sempre.
Assim o bug nunca volta sem você perceber.

---

## 5. Quando a entrada é grande: minimizar

Às vezes o crash vem com centenas de bytes. Peça para o fuzzer **encolher** a
entrada, mantendo o crash:

```
ALVO=soma ./fuzzer -minimize_crash=1 -runs=10000 crash-XXXX
```

Ele escreve versões menores (`minimized-from-...`). Quanto menor a entrada, mais
fácil entender o que a causou.

---

## 6. Resumo: onde olhar

| Quero saber... | Olho para... |
|---|---|
| Que o programa travou | `deadly signal` |
| Em que função | a **primeira** função sua na pilha (`#4`) |
| Em que linha | pilha da versão `-Onone -g` (`Harness.swift:20`) |
| Por que travou | mensagem do `precondition` (só aparece sem `-O`) |
| Qual entrada causou | arquivo `crash-...` / linha `0x0,0x0,...` |
| O que a entrada significa | o decodificador (formato dos bytes) |
| Se já consertei | rodar o `crash-...` de novo depois de recompilar |

## 7. Erros comuns

- **Ver só "deadly signal" e achar que não dá para saber o motivo.** Rode o
  arquivo `crash-...` em uma versão compilada com `-Onone -g`.
- **Esquecer de recompilar** depois de editar o código e achar que o bug sumiu.
- **Procurar o erro nas linhas do libFuzzer** (`#0` a `#3`, `#7+`). O código é
  seu: procure a primeira função com nome seu.
- **Apagar o `crash-...`** antes de consertar. Sem ele, você perde a forma mais
  fácil de reproduzir o erro.

## 8. Exercício

1. Rode o fuzzer na versão mutada e anote o nome do arquivo `crash-...`.
2. Decodifique os bytes **à mão** (tipo e centavos) antes de reproduzir.
3. Reproduza em `-Onone -g` e confira se a sua conta bate com "obtido" e
   "esperado".
4. Faça outra mutação (por exemplo, ignorar a primeira transação) e repita:
   que entrada o fuzzer achou? Por que esse bug precisa de **2 ou mais**
   transações para aparecer?
