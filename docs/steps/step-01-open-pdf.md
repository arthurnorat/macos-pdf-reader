# Step 01 — Abrir um PDF

## Objetivo

Uma janela que mostra um PDF. O arquivo chega por cinco caminhos: botão
**Open…**, **File › Open…** (⌘O), **File › Open Recent**, arrastar para a
janela e Finder/Dock. Cada janela está em um de três estados: **vazia**,
**PDF carregado** ou **erro** com mensagem para o usuário.

## Decisões

**macOS 14 como mínimo.** O SDK (Xcode 26) define quais APIs existem; o
*deployment target* define o macOS mais antigo em que o app roda. Com 14, o
app roda em Macs mais antigos e o compilador barra APIs mais novas sem
`if #available`. O 14 já tem tudo o que usamos (`@Observable`,
`ContentUnavailableView`, `WindowGroup(for:)`).

**PDF como Document Type (`Info.plist`).** Sem isso, o Finder não oferece o
app em *Abrir com* e o Dock recusa o arquivo. Tipo `com.adobe.pdf` (UTI, o
identificador oficial do formato), papel `Viewer` (só lê) e rank `Alternate`
(aparece em *Abrir com* sem tirar o Preview de padrão).

**Recentes via `NSDocumentController`.**

| Opção | Ganha | Custa |
|---|---|---|
| `NSDocumentController` (escolhida) | O sistema guarda a permissão do sandbox de cada item; funciona depois de relançar. | Não é observável: precisamos espelhar a lista. |
| Lista própria com *security-scoped bookmarks* | Controle total. | Mais código e um entitlement a mais. |

**`NSOpenPanel` em vez de `.fileImporter`.** ⌘O precisa funcionar sem
nenhuma janela aberta, e o `.fileImporter` precisa de uma view onde se
pendurar.

**Uma regra única de roteamento.** Se a janela que recebeu o pedido está
vazia, o primeiro arquivo entra nela; os demais abrem em janelas novas. Assim
não sobra janela vazia, e os cinco caminhos se comportam igual.

**Estado como `enum`.** `empty`, `loaded(PDFDocument)` e
`failed(message:)`: a janela está sempre em exatamente um estado. Com vários
opcionais soltos, estados impossíveis (documento *e* erro) seriam possíveis.

**Carregamento síncrono.** `PDFDocument(url:)` não lê o arquivo inteiro de
uma vez, então abrir é rápido. Fazer em segundo plano traria complexidade de
concorrência (`PDFDocument` não é `Sendable`) sem um problema real a
resolver.

**PDF com senha → `.unreadable`.** Pedir a senha seria uma funcionalidade
nova, fora do escopo.

## ADR

### ADR 1 — `WindowGroup(for: URL.self)` em vez de `DocumentGroup`

**Contexto.** O `DocumentGroup` traz Abrir, Recentes e restauração de graça,
mas assume um arquivo = uma janela e foi feito para apps que editam. O app só
lê e precisa abrir o mesmo arquivo em várias abas.

**Decisão.** `WindowGroup(for: URL.self)`: cada janela é identificada pela URL
do PDF (`nil` = vazia) e tem o próprio ViewModel e `PDFDocument`.

**Consequências.** Janelas independentes, base para as abas do step 03. Em
troca, fizemos à mão o menu (`FileCommands`), a abertura pelo Finder e o
`WindowRouter`. O `WindowGroup(for:)` não duplica janelas com o mesmo valor;
o step 03 troca o valor por `ReaderTab` (URL + `UUID`) para permitir o mesmo
arquivo em várias abas. Reverter exigiria um tipo `NSDocument` e abrir mão das abas
repetidas.

### ADR 2 — Sandbox sem acesso à rede

**Contexto.** Autos de processos contêm dados sigilosos; o conteúdo não pode
sair da máquina.

**Decisão.** App Sandbox ligado, com um único entitlement: arquivos
escolhidos pelo usuário, somente leitura. Sem entitlement de rede e sem
telemetria.

**Consequências.** A privacidade é garantida pelo sistema operacional, não
só pelo código. O app só lê o que o usuário entregou (painel, arraste,
Finder, recentes). Funcionalidades online ficam impossíveis sem reabrir esta
decisão; lembrar arquivos entre execuções exige mecanismos do sistema.

## Como o código funciona

```
PDFReaderApp ── WindowGroup(for: URL) ──> ReaderWindowView ──> ReaderViewModel
      └── .commands ──> FileCommands                              ├──> DocumentService ──> AppError
         (ambos usam WindowRouter e PDFOpenPanel)                 └──> RecentDocumentsService
```

**`Models/AppError.swift`** — os três erros que o usuário pode ver:
`.fileNotFound`, `.notAPDF`, `.unreadable`.

**`Services/DocumentService.swift`** — transforma uma URL em `PDFDocument`
ou em `AppError`, checando na ordem: o arquivo existe? É PDF (pelo `UTType`)?
O PDFKit consegue abrir? A função é `throws(AppError)` (*typed throws*): o
compilador sabe que ela só lança `AppError`, então o `catch` recebe o tipo
certo e o `switch` precisa cobrir todos os casos.

**`Services/RecentDocumentsService.swift`** — embrulha o
`NSDocumentController` numa classe `@Observable`. A macro `@Observable` faz
o SwiftUI redesenhar quem lê uma propriedade quando ela muda; aqui, o menu
Open Recent. É um *singleton* (`static let shared`) porque a lista do
sistema também é única.

**`ViewModels/ReaderViewModel.swift`** — um por janela. `load(_:)` chama o
serviço, guarda o estado e, só em caso de sucesso, adiciona aos recentes. A
mensagem de cada erro sai de um `switch` exaustivo.

**`Views/PDFReaderView.swift`** — `NSViewRepresentable` é o adaptador que
coloca uma view do AppKit (`PDFView`) dentro do SwiftUI: `makeNSView` cria,
`updateNSView` atualiza. `unregisterDraggedTypes()` existe porque o
`PDFView` recusa arquivos arrastados e, por estar por cima, impediria o
arraste de chegar ao SwiftUI.

**`Views/PDFOpenPanel.swift`** — mostra o painel Abrir limitado a PDFs. No
sandbox, a escolha do usuário nesse painel é o que dá ao app permissão de
ler o arquivo.

**`Views/WindowRouter.swift`** — aplica a regra de roteamento. Recebe um
`Binding<URL?>` (referência de leitura e escrita para o valor da janela) e
usa `openWindow(value:)` para as janelas novas. Também declara o
`FocusedValues.documentURL`, o canal pelo qual a janela em foco informa sua
URL ao menu.

**`Views/ReaderWindowView.swift`** — o conteúdo da janela. Pontos-chave:
- `.onChange(of: url, initial: true)` carrega o arquivo quando a janela nasce
  e quando a URL muda;
- `.dropDestination` recebe arrastes; `.contentShape(Rectangle())` faz a
  janela inteira aceitá-los, não só as partes desenhadas;
- `.onOpenURL` recebe arquivos do Finder, e
  `.handlesExternalEvents(preferring: ["*"], allowing: ["*"])` faz uma
  janela existente recebê-los, para que passem pelo router;
- `ContentUnavailableView` desenha os estados vazio e de erro.

**`Views/FileCommands.swift`** — `Commands` monta a barra de menus. Lê a
janela em foco com `@FocusedValue` para saber onde abrir o arquivo.

**`PDFReaderApp.swift`** — declara o `WindowGroup(for: URL.self)` e os
comandos.

## Conexão com o próximo step

O app abre PDFs por todos os caminhos do macOS. O step 02 cuida de **como**
a página aparece: uma folha inteira por vez e tela cheia.
