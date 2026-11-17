# Step 01 — Abrir um PDF

## Objetivo

Entregar a primeira versão útil do app: uma janela que mostra um PDF. O PDF
pode chegar por cinco caminhos, e todos terminam no mesmo lugar:

| Caminho | Quem dispara |
|---|---|
| Botão **Open…** na janela vazia ou de erro | `ReaderWindowView` |
| **File › Open…** (⌘O) | `FileCommands` |
| **File › Open Recent** | `FileCommands` |
| Arrastar um arquivo para dentro da janela | `.dropDestination` |
| Finder (duplo clique, *Abrir com*, arrastar no ícone do Dock) | `.onOpenURL` |

Cada janela tem três estados possíveis: **vazia**, **PDF carregado** ou
**erro** com uma mensagem para o usuário. Zoom, tela cheia, abas e teclado
ficam para os steps 02 a 04.

Este step também fixa duas decisões de arquitetura (ver "ADR"):
`WindowGroup(for:)` em vez de `DocumentGroup`, e sandbox sem rede.

---

## Decisões

### 1. macOS 14 como versão mínima

O template do Xcode 26.2 criou o projeto com *Minimum Deployments* = 26.2.
Mudamos para 14.0.

- **Versão do Xcode/SDK** = quais APIs *existem* para compilar.
- **Deployment target** = o macOS *mais antigo* em que o app aceita rodar.

| Opção | Ganha | Custa |
|---|---|---|
| **macOS 14** (escolhida) | Roda em Macs mais antigos. O compilador **barra** o uso de API mais nova sem `if #available`. | Não dá para usar API do 15/26 sem uma verificação de versão. |
| macOS 26.2 | Libera tudo que é novo. | O app só abre no macOS 26. |

O macOS 14 já tem tudo de que o projeto precisa: `@Observable`,
`ContentUnavailableView`, `onChange(of:initial:)` e `WindowGroup(for:)`.

Detalhe: no `.pbxproj`, o **projeto** continua em 26.2 e o **target** está em
14.0. A configuração do target *sobrescreve* a do projeto, então vale 14.0.

### 2. Declarar PDF como "Document Type" (Viewer, Alternate)

Para o Finder oferecer o app em *Abrir com* e o Dock aceitar um PDF arrastado,
o macOS precisa saber **sem executar o app** quais tipos ele abre. Isso fica
no `Info.plist`, na chave `CFBundleDocumentTypes`:

```xml
<key>CFBundleTypeRole</key>   <string>Viewer</string>
<key>LSHandlerRank</key>      <string>Alternate</string>
<key>LSItemContentTypes</key> <array><string>com.adobe.pdf</string></array>
```

- **`LSItemContentTypes = com.adobe.pdf`**: o tipo é identificado pelo
  **UTI** (*Uniform Type Identifier*), o "nome oficial" de um formato no
  macOS. É mais robusto que olhar a extensão `.pdf`.
- **`Viewer` vs `Editor`**: o app só lê. `Editor` prometeria ao sistema que
  ele também salva.
- **`Alternate` vs `Default`**: com `Alternate`, o app aparece em *Abrir com*,
  mas o Preview continua sendo o app padrão para PDFs. Trocar para `Default`
  depois é só mudar um campo.
- **Class vazia**: esse campo aponta para uma subclasse de `NSDocument`, a
  base do `DocumentGroup`. Não usamos `NSDocument` (ver ADR 1).

O Xcode gravou essa configuração num arquivo `PDFReader/Info.plist`. O
Info.plist final do app é a **soma** das chaves geradas automaticamente
(`GENERATE_INFOPLIST_FILE = YES`) com as deste arquivo.

### 3. Recentes: o menu nativo do sistema, espelhado num `@Observable`

| Opção | Ganha | Custa |
|---|---|---|
| **`NSDocumentController` + espelho observável** (escolhida) | A lista é a do sistema: também aparece no menu do ícone do Dock. O sistema guarda a permissão do sandbox para cada item. | `NSDocumentController` não é observável, então precisamos de uma cópia da lista para o SwiftUI reagir. |
| Lista própria com *security-scoped bookmarks* | Controle total, dá para mostrar na tela vazia. | Mais código, um entitlement a mais (`files.bookmarks.app-scope`) e mais conceitos novos de uma vez. |

O ponto mais importante é a **permissão do sandbox**. Um app com sandbox só lê
arquivos que o usuário escolheu. Depois de fechar e abrir o app de novo, uma
URL "crua" perde essa permissão. O `NSDocumentController` guarda cada item
recente junto com essa permissão. Por isso **Open Recent funciona mesmo
depois de relançar o app**, o que foi confirmado na verificação.

A lista própria fica para quando precisarmos dela de verdade: o
"lembrar a posição por arquivo" da fase 2.

### 4. `NSOpenPanel` em vez de `.fileImporter`

| Opção | Ganha | Custa |
|---|---|---|
| **`NSOpenPanel`** (escolhida) | Funciona **sem nenhuma janela aberta** (⌘O com o app vazio). As URLs já vêm com permissão de leitura. | É AppKit, não SwiftUI "puro". |
| `.fileImporter` (SwiftUI) | Declarativo. | Precisa de uma view onde se pendurar, então não serve para ⌘O sem janelas. As URLs exigem `startAccessingSecurityScopedResource()`. |

### 5. Uma regra única de roteamento: "a janela vazia é reaproveitada"

Os cinco caminhos de abertura passam pelo mesmo `WindowRouter`:

- se a janela que recebeu o pedido está **vazia**, o primeiro arquivo entra
  nela;
- todos os outros arquivos abrem em **janelas novas**.

A alternativa, "sempre uma janela nova", deixaria uma janela vazia esquecida
toda vez que você abre o app e escolhe um arquivo. Ter a regra num lugar só
garante que os cinco caminhos se comportam igual.

### 6. Estado da janela como `enum`, não como vários opcionais

```swift
enum State { case empty, loaded(PDFDocument), failed(message: String) }
```

Com três propriedades soltas (`document: PDFDocument?`, `error: String?`,
`isEmpty: Bool`) seria possível ter estados **impossíveis**, como um
documento *e* um erro ao mesmo tempo. Com o `enum`, a janela está sempre em
exatamente um estado, e o `switch` da View é verificado pelo compilador.

### 7. Carregamento síncrono, sem estado "carregando"

O global CLAUDE.md pede estado de *loading* em telas SwiftUI. Aqui ele não
existe **de propósito**: `PDFDocument(url:)` não lê o arquivo inteiro. Ele lê
a estrutura do PDF e desenha cada página só quando ela aparece na tela. Na
verificação, um PDF de 500 páginas (9 MB) abriu sem atraso visível.

| Opção | Ganha | Custa |
|---|---|---|
| **Síncrono** (escolhida) | Simples; nenhum conceito de concorrência novo agora. | Um PDF gigante numa rede lenta poderia travar a janela por um instante. |
| `async` em segundo plano | Nunca trava a interface. | `PDFDocument` não é `Sendable` (não pode passar entre threads com segurança). Isso traria complexidade de concorrência sem um problema real a resolver. |

Se um PDF real dos autos travar a abertura, este é o ponto a revisitar.

### 8. Erros tipados com `throws(AppError)` e PDFs com senha

`DocumentService.loadDocument` declara `throws(AppError)` (*typed throws*,
Swift 6). Isso diz ao compilador que a função **só** lança `AppError`. No
`catch`, a variável `error` já é `AppError`, sem precisar de *cast*, e o
`switch` sobre ela precisa cobrir todos os casos.

Um PDF protegido por senha de abertura cai em `.unreadable`, junto com os
PDFs corrompidos. Criar um caso `.locked` com uma tela para digitar a senha
seria uma funcionalidade nova, fora do escopo.

### 9. `.gitignore` antes do primeiro commit

Ele ignora três grupos de arquivos:

- **estado pessoal do Xcode e build:** `xcuserdata/`, `DerivedData/`;
- **arquivos de segredo:** `.env*`, `.pem`, `.p12`, mesmo que ainda não
  existam;
- **todos os `*.pdf`:** os PDFs de teste ficam fora do repositório, e um PDF
  real de processo nunca pode ser commitado por acidente.

---

## ADR

### ADR 1 — `WindowGroup(for: URL.self)` em vez de `DocumentGroup`

**Contexto.** O SwiftUI tem duas formas de criar janelas ligadas a arquivos.
O `DocumentGroup` é o caminho "oficial" para apps de documentos: ele usa
`NSDocument` por baixo e traz de graça Abrir, Recentes e restauração de
janelas. Só que ele parte de uma premissa: **um arquivo = um documento = uma
janela**. O app precisa de outra coisa: ler os mesmos autos em várias abas ao
mesmo tempo (por exemplo, a petição numa aba e a sentença em outra). Além
disso, o app nunca salva nada; é só leitura.

**Decisão.** Usar `WindowGroup(for: URL.self)`. Cada janela é identificada
pela URL do PDF que mostra (`nil` para uma janela vazia) e tem o próprio
`ReaderViewModel` e o próprio `PDFDocument`.

**Consequências.**
- ✅ Cada janela é independente, o que é a base para as abas do step 03.
- ✅ Nenhuma maquinaria de edição e salvamento (`NSDocument`) para um app que
  só lê.
- ❌ O que o `DocumentGroup` dava de graça foi feito à mão: o menu Open/Open
  Recent (`FileCommands`), a abertura pelo Finder (`.onOpenURL`) e a regra de
  qual janela recebe o arquivo (`WindowRouter`).
- ⚠️ O `WindowGroup(for:)` **não duplica janelas para o mesmo valor**. Pedir
  para abrir uma URL que já está aberta traz a janela existente para frente
  (comportamento confirmado na verificação). Hoje isso é bom, mas o step 03
  ("o mesmo arquivo em duas abas") vai precisar de um valor que identifique
  *a aba*, e não só o arquivo: por exemplo, uma struct com a URL e um `UUID`.
- ⚠️ O macOS **restaura as janelas** ao reabrir o app, junto com o valor
  (URL) de cada uma. Isso depende do ajuste do sistema "Fechar janelas ao
  encerrar um app". Na verificação, as janelas restauradas abriram os PDFs
  normalmente, mas isso não foi tratado de propósito. O assunto volta no
  passo "lembrar a posição por arquivo".
- **Custo de reverter:** trocar para `DocumentGroup` exigiria criar um tipo
  `FileDocument`/`NSDocument`, apagar o `WindowRouter` e o `FileCommands`, e
  abriria mão das várias abas do mesmo arquivo.

### ADR 2 — Sandbox sem acesso à rede

**Contexto.** O app vai abrir PDFs de processos judiciais, que podem conter
dados pessoais e sigilosos. A promessa do projeto é que o conteúdo **nunca
sai da máquina**.

**Decisão.** O App Sandbox fica ligado (`ENABLE_APP_SANDBOX = YES`) com só um
entitlement de arquivos: **arquivos escolhidos pelo usuário, somente
leitura** (`com.apple.security.files.user-selected.read-only`). **Não** há
entitlement de rede (`network.client`/`network.server`). O app também não
tem telemetria.

**Consequências.**
- ✅ A garantia de privacidade vem do **sistema operacional**, não só do
  código. Mesmo que uma biblioteca tentasse abrir uma conexão, o kernel
  bloquearia.
- ✅ O app só lê arquivos que o usuário entregou: pelo painel, arrastando,
  pelo Finder ou pelos recentes guardados pelo sistema.
- ❌ Nenhuma funcionalidade online é possível (atualização automática, busca
  na web) sem reabrir esta decisão.
- ❌ Lembrar arquivos entre execuções exige mecanismos do sistema (os recentes
  do `NSDocumentController` hoje, *security-scoped bookmarks* no futuro), e
  não basta guardar caminhos.
- **Custo de reverter:** ligar a rede é um checkbox. O custo real é perder a
  garantia de privacidade, que é o motivo do app existir.

---

## Como o código funciona

Mapa das camadas:

```
PDFReaderApp ── WindowGroup(for: URL) ──> ReaderWindowView  (View)
      └── .commands ──> FileCommands                        (View/menu)
                               │ ambos usam
                         WindowRouter, PDFOpenPanel          (View/apoio)
ReaderWindowView ──> ReaderViewModel                         (ViewModel)
                         ├──> DocumentService                (Service)
                         └──> RecentDocumentsService         (Service)
DocumentService ──throws──> AppError                         (Model)
```

O projeto usa *synchronized folders* do Xcode 16+: qualquer arquivo criado
dentro de `PDFReader/` entra no target sozinho, sem editar o `.pbxproj`.

### `Models/AppError.swift`

O `enum` com os três erros que o usuário pode ver: `.fileNotFound`,
`.notAPDF` e `.unreadable`. Os casos descrevem o problema **do ponto de vista
do usuário**, e não qual API falhou. O texto mostrado na tela não fica aqui;
ele fica no ViewModel, que é a camada que conversa com a tela.

`Equatable` permite comparar erros (`error == .notAPDF`), o que é útil em
testes manuais e em lógica futura.

### `Services/DocumentService.swift`

Transforma uma URL num `PDFDocument` ou num `AppError`. As verificações vão
da mais barata para a mais cara, para cada falha ganhar o erro mais preciso:

```swift
guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
    throw .fileNotFound
}
// ... lê o tipo do arquivo (UTType) ...
guard let contentType = values.contentType, contentType.conforms(to: .pdf) else {
    throw .notAPDF
}
guard let document = PDFDocument(url: url) else { throw .unreadable }
guard !document.isLocked, document.pageCount > 0 else { throw .unreadable }
```

- `path(percentEncoded: false)` devolve o caminho com espaços e acentos
  "normais", e não `%20`.
- `throw .fileNotFound`: como a função é `throws(AppError)`, o Swift sabe o
  tipo e aceita só `.fileNotFound`, sem escrever `AppError.`.
- `UTType.conforms(to: .pdf)`: tipos no macOS formam uma hierarquia. Um tipo
  "conforma" a `.pdf` se *for* PDF.
- Um `.txt` renomeado para `.pdf` passa no teste do tipo (o tipo vem da
  extensão), mas o `PDFDocument(url:)` devolve `nil`, então vira
  `.unreadable`. Foi exatamente o que aconteceu com o `fake.pdf` na
  verificação.
- O `do/catch` em volta de `resourceValues` **não engole** o erro: ele vira
  `.unreadable` de forma explícita, como pede a regra de erros tipados.

### `Services/RecentDocumentsService.swift`

```swift
@Observable
final class RecentDocumentsService {
    static let shared = RecentDocumentsService()
    private(set) var urls: [URL]
    func add(_ url: URL) { controller.noteNewRecentDocumentURL(url); urls = controller.recentDocumentURLs }
    func clear() { ... }
}
```

- **`@Observable`** (macOS 14): uma macro que faz o SwiftUI "assinar" as
  propriedades que uma view lê. Quando `urls` muda, só quem leu `urls`
  (aqui, o menu Open Recent) é redesenhado.
- **`static let shared`** (*singleton*): existe uma instância só, porque a
  lista que ela embrulha também é única para o app todo. O `private init()`
  impede criar outras.
- **`private(set)`**: qualquer um lê `urls`, mas só a própria classe altera.
- `noteNewRecentDocumentURL` só aceita tipos declarados em
  `CFBundleDocumentTypes`. É mais um motivo para a Decisão 2.

### `ViewModels/ReaderViewModel.swift`

Um ViewModel por janela. A View só lê `state` e chama `load(_:)`.

```swift
func load(_ url: URL?) {
    guard let url else { state = .empty; return }
    do {
        let document = try documentService.loadDocument(at: url)
        state = .loaded(document)
        recents.add(url)               // só entra nos recentes se abriu
    } catch {
        state = .failed(message: Self.message(for: error, fileName: url.lastPathComponent))
    }
}
```

- Só arquivos que **abriram com sucesso** entram nos recentes. Na
  verificação, `fake.pdf` e `notes.txt` não apareceram no menu.
- `message(for:fileName:)` é um `switch` exaustivo. Se amanhã surgir um caso
  novo em `AppError`, o compilador aponta este lugar.
- **Injeção de dependências pelo `init`** com valores padrão
  (`DocumentService()`, `.shared`): a View cria o ViewModel com
  `ReaderViewModel()`, mas daria para passar outras implementações se um dia
  for preciso.

### `Views/PDFReaderView.swift`

O SwiftUI não tem uma view de PDF. **`NSViewRepresentable`** é o adaptador
que coloca uma `NSView` do AppKit dentro do SwiftUI:

- `makeNSView` roda **uma vez** e cria o `PDFView`;
- `updateNSView` roda **sempre que as entradas mudam**.

```swift
if pdfView.document !== document { pdfView.document = document }
```

`!==` compara **identidade** (se é o mesmo objeto na memória), e não
conteúdo. Reatribuir o mesmo documento faria o `PDFView` voltar para a
primeira página sem motivo.

**Por que `pdfView.unregisterDraggedTypes()`.** No AppKit, uma view que quer
receber arrastes se registra com `registerForDraggedTypes`. O macOS entrega o
arraste à view **mais ao fundo da hierarquia, ou seja, a mais interna,** que
está sob o cursor e que se registrou. O `PDFView` se registra, mas recusa
arquivos (a propriedade `acceptsDraggedFiles` dele vem como `false`). Como ele
fica *por cima* da área do SwiftUI, o arraste morria nele e o arquivo
"voltava" para o Finder.

Desfazendo o registro, o arraste atravessa o `PDFView` e chega ao
`.dropDestination` da janela, onde o `WindowRouter` decide o que fazer. Isso
foi confirmado na verificação: soltar um PDF sobre outro PDF abre uma janela
nova.

A alternativa seria ligar `acceptsDraggedFiles = true`. Aí o próprio
`PDFView` trocaria o documento, **sem passar pelo ViewModel**: sem erro
tipado, sem recentes e sem a regra de janelas. Essa opção foi descartada.

Este é o lugar onde o step 04 troca `PDFView` por `KeyboardPDFView`.

### `Views/PDFOpenPanel.swift`

Um `enum` sem casos usado só como "namespace" para a função estática
`choosePDFs()`. Ele configura o `NSOpenPanel` (só PDFs, vários arquivos,
sem pastas) e devolve as URLs escolhidas, ou `[]` se o usuário cancelar.
`runModal()` bloqueia até o usuário decidir.

No sandbox, esse painel roda num **processo separado do sistema** (o
*PowerBox*). É a escolha do usuário nesse painel que concede ao app a
permissão de ler aqueles arquivos.

### `Views/WindowRouter.swift`

```swift
func open(_ urls: [URL], into current: Binding<URL?>?) {
    var remaining = urls[...]
    if let current, current.wrappedValue == nil, let first = remaining.popFirst() {
        current.wrappedValue = first
    }
    for url in remaining { openWindow(value: url) }
}
```

- `urls[...]` cria um **`ArraySlice`**, uma "visão" do array, que tem
  `popFirst()`.
- **`Binding<URL?>`** é uma referência de leitura **e escrita** para um valor
  que vive em outro lugar (aqui, o valor da janela no `WindowGroup`). Escrever
  em `current.wrappedValue` troca o arquivo da janela.
- **`OpenWindowAction`** (`openWindow(value:)`) pede ao SwiftUI uma janela
  para aquele valor. Se ela já existe, a janela existente vem para frente.

O mesmo arquivo declara o `FocusedValues.documentURL` com a macro **`@Entry`**:
um "canal" pelo qual a janela em foco publica sua URL para o menu ler.

### `Views/ReaderWindowView.swift`

O conteúdo de cada janela. Os modificadores principais:

| Modificador | Para quê |
|---|---|
| `.onChange(of: url, initial: true)` | Carrega o arquivo quando a janela nasce (`initial: true`) e sempre que a URL muda. |
| `.navigationTitle(...)` | Nome do arquivo na barra de título. |
| `.dropDestination(for: URL.self)` | Aceita arquivos arrastados para a janela. |
| `.onOpenURL` | Recebe arquivos abertos pelo Finder ou pelo Dock. |
| `.focusedSceneValue(\.documentURL, $url)` | Publica a URL desta janela para o `FileCommands`. |

Dois modificadores existem por causa de bugs encontrados na verificação:

- **`.frame(maxWidth: .infinity, maxHeight: .infinity)` + `.contentShape(Rectangle())`.**
  No SwiftUI, uma view só "existe" para cliques e arrastes onde algo está
  **desenhado**. O `ContentUnavailableView` desenha só o ícone, o texto e o
  botão; o resto é transparente. Um PDF solto no canto vazio da janela era
  recusado. `maxWidth/maxHeight: .infinity` faz a view ocupar a janela
  inteira, e `contentShape(Rectangle())` declara que *todo* esse retângulo
  responde, desenhado ou não.
- **`.handlesExternalEvents(preferring: ["*"], allowing: ["*"])`.** Por
  padrão, para cada arquivo aberto pelo Finder, o SwiftUI cria uma janela
  **nova e vazia** e entrega a URL nela. O router via uma janela vazia e
  colocava o arquivo ali direto, sem passar pelo `openWindow(value:)`, que é
  quem verifica se o arquivo já está aberto. Resultado: o mesmo arquivo em
  duas janelas. Com `"*"` (aceita qualquer URL), uma janela **existente**
  recebe o evento e tudo passa pelo router. Sem nenhuma janela aberta, o
  SwiftUI ainda cria uma.

O `switch viewModel.state` escolhe entre três telas. A vazia e a de erro usam
o **`ContentUnavailableView`** (macOS 14), a tela padrão da Apple para "não
há conteúdo aqui", com ícone, texto e botões.

Um detalhe no botão **Open…** do estado de erro: a janela já tem uma URL (a
que falhou), então o router abriria uma janela nova. Por isso a URL é limpa
antes de abrir, e o arquivo novo **substitui** o que falhou na mesma janela.

### `Views/FileCommands.swift`

**`Commands`** é como o SwiftUI monta a barra de menus.
`CommandGroup(after: .newItem)` insere os itens logo depois de "New Window".

O menu vive no nível do app, e não dentro de uma janela. Por isso ele usa
**`@FocusedValue(\.documentURL)`** para saber qual janela está em foco. Se
nenhuma estiver, o valor é `nil` e o router abre uma janela nova.

O atalho ⌘O está aqui por enquanto, via `.keyboardShortcut("o")`. No step 04,
todos os atalhos passam para `KeyBindings.swift`.

### `PDFReaderApp.swift`

```swift
WindowGroup(for: URL.self) { $url in
    ReaderWindowView(url: $url)
}
.commands { FileCommands() }
```

O `$url` é um `Binding<URL?>`: `nil` numa janela vazia (como a que aparece ao
abrir o app), ou a URL do arquivo.

### `Info.plist` e `.gitignore`

Ver as Decisões 2 e 9.

---

## Conexão com o próximo step

Agora o app abre qualquer PDF por todos os caminhos que o macOS oferece e
mostra erros claros. O PDF aparece com o zoom padrão do PDFKit (100%), numa
janela com barra de título comum.

O **step 02 — superfície de leitura** cuida da experiência de leitura:

- **visualização padrão de uma folha inteira**: a página em pé ocupa a
  janela de cima a baixo, como o "Zoom to Page Level" do Acrobat. É um
  requisito central do app e substitui a ideia original de encaixar a
  largura;
- janela com aparência sem bordas, para a página aproveitar o espaço;
- tela cheia.

Tudo isso acontece dentro do `PDFReaderView` e da configuração da janela, sem
mudar o fluxo de abertura deste step.
