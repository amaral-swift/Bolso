# Desafio: migração de esquema no Bolso

## A ideia

Um usuário que já tem o app instalado guarda os dados no formato antigo. Quando
você publica uma versão com o `@Model` alterado, o SwiftData precisa converter
esse arquivo sem perder nada. Aqui você pratica isso em três etapas, da mais
simples à mais difícil.

Antes de começar, assista ao vídeo principal:
[Model your schema with SwiftData (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10195/).

## Preparação

1. Crie uma branch (`git switch -c migracao-swiftdata`) para poder voltar atrás.
2. Resolva a pendência do `Categoria.init`: o parâmetro `valorTotal` não é
   usado. Remova-o (e os lugares que o passam) **antes** de congelar a V1.
3. Rode o app e cadastre dados de teste: pelo menos 3 categorias e 5 transações
   (com receita e gasto). Esses dados são a sua "base de usuário real".

---

## Etapa 1: congelar a V1

**Objetivo:** descrever o esquema atual como `SchemaV1`, sem mudar o
comportamento do app.

O que fazer:

1. Crie um arquivo `Schemas.swift`.
2. Crie `enum SchemaV1: VersionedSchema` com `versionIdentifier` `1.0.0` e a
   lista de `models`.
3. Mova `Categoria` e `Transacao` (como estão hoje) para dentro da `SchemaV1`.
4. Crie `enum PlanoDeMigracao: SchemaMigrationPlan` com só a V1 e nenhum stage.
5. Passe o plano ao `.modelContainer` em `GastosAppApp.swift`.

Como saber se deu certo:

- [ ] O app compila e abre.
- [ ] As 3 categorias e 5 transações continuam aparecendo.

Pergunta: por que mover as classes para dentro da `SchemaV1`? O que aconteceria
com a V1 se você editasse `Transacao` depois, no arquivo original?

---

## Etapa 2: migração leve (lightweight)

**Objetivo:** adicionar um campo novo sem perder os dados.

Mudança: em `Transacao`, acrescente `recorrente: Bool` com valor padrão `false`.

O que fazer:

1. Duplique o esquema como `SchemaV2` (`2.0.0`). **A V1 não pode mudar.**
2. Faça a alteração só na V2.
3. Adicione a V2 em `schemas` e crie um stage `.lightweight` de V1 para V2.
4. Atualize os `typealias` do app para apontar para as classes da V2, para o
   resto do código continuar usando `Transacao` e `Categoria`.

Como saber se deu certo:

- [ ] O app abre sem apagar o banco.
- [ ] As 5 transações antigas continuam lá, todas com `recorrente == false`.
- [ ] Uma transação nova aceita `recorrente == true` e mantém o valor depois de
      fechar e abrir o app.

Pergunta: qual é a diferença entre rodar o app com os dados da V1 e apagar o
app antes de instalar a V2? Qual das duas é o teste que importa?

---

## Etapa 3: migração customizada

**Objetivo:** mexer nos dados durante a migração.

Mudança: em `Categoria`, o campo `nome` já é `.unique`. Imagine que, na V1, ele
**não** era único, e agora você quer tornar único. Se o usuário tem duas
categorias "Mercado", a migração vai quebrar.

Para treinar, use uma versão **só de estudo**:

1. Na `SchemaV2`, tire o `@Attribute(.unique)` de `nome` (a V2 não exige).
2. Cadastre duas categorias com o mesmo nome (ex.: "Mercado" duas vezes) na V2.
3. Crie a `SchemaV3` com `nome` único.
4. Crie um stage **custom** de V2 para V3:
   - no `willMigrate`, procure categorias duplicadas;
   - junte as transações de todas em **uma só** e apague as repetidas;
   - salve o contexto.
5. Rode o app com os dados da V2 e confira o resultado.

Como saber se deu certo:

- [ ] O app abre com o plano V1 → V2 → V3.
- [ ] Existe uma única categoria "Mercado".
- [ ] As transações das duas categorias antigas estão na categoria que sobrou.
- [ ] O total (`valorTotal`) da categoria é a soma das duas anteriores.

Perguntas:

- Por que a mesma lógica não funciona só com um stage lightweight?
- Qual é a diferença entre `willMigrate` e `didMigrate`? Em qual deles você
  mexe nos dados da versão antiga?

---

## Erros comuns

- **Editar a V1 depois de publicada.** A V1 descreve o passado, ela não pode mudar.
- **Esquecer de atualizar o plano** com a versão nova em `schemas` e `stages`.
- **Testar só com app limpo.** O teste que vale é com dados da versão anterior.
- **Criar uma versão para toda mudança.** Em alguns casos (como adicionar uma
  propriedade com valor padrão) pode ser desnecessário. Leia o texto do
  [Donny Wals](https://www.donnywals.com/a-deep-dive-into-swiftdata-migrations/)
  e confira o que o seu caso exige.

## Bônus

- Escreva um teste que cria um container na V1, insere dados, migra para a V3 e
  confere o resultado (use um container em memória ou um arquivo temporário).
- Mostre uma tela de "atualizando seus dados" durante a migração.
- Veja a novidade do WWDC25 em
  [Dive into inheritance and schema migration](https://developer.apple.com/videos/play/wwdc2025/291/)
  e descubra para que serve `propertiesToFetch`.
