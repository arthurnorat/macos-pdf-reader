# Step 04 — Teclado

## Objetivo

Ler os autos sem tirar a mão do teclado: virar página, ir para a primeira ou
a última, dar zoom e voltar à folha inteira. Todos os atalhos ficam num único
arquivo e aparecem nos menus **Go** e **View**.

## Decisões

**Só teclas do macOS, sem Vim.** Setas, Espaço, Page Up/Down, Home/End e ⌘
são as teclas que qualquer usuário de Mac já conhece. As letras ficam livres
para recursos futuros (busca, copiar o Num.).

**Um tipo `ReaderCommand` para menu e teclado.** O menu e o teclado chamam o
mesmo comando. Assim não há duas implementações de "próxima página" que
possam divergir.

**Subclasse de `PDFView` para as teclas.** A alternativa era um monitor
global de eventos (`NSEvent.addLocalMonitorForEvents`), que intercepta teclas
do app inteiro, inclusive de outras telas. Com a subclasse, só a view do PDF
em foco reage, que é o comportamento de *responder chain* do AppKit: a tecla
vai primeiro para a view em foco.

**Com zoom, as setas e o Espaço rolam.** Na folha inteira, eles viram a
página. Com zoom, a página não cabe na tela: ↓ ↑, Page Up/Down e Espaço usam a
rolagem do PDFKit, e → ← rolam na horizontal por código nosso, porque o
PDFKit as ignora.

**Atalhos no menu, só os com ⌘.** Os menus deixam os atalhos descobríveis e
ficam desabilitados quando a aba não mostra um PDF. Um atalho de menu é
consultado **antes** da view; se → estivesse no menu, ele sempre viraria a
página e a view nunca saberia do zoom. Por isso Next/Previous Page aparecem no
menu sem atalho.

## Como o código funciona

**`Views/KeyBindings.swift`** — o único lugar com atalhos.
- `ReaderCommand` lista os comandos, com o título e o atalho de menu de cada
  um (`nil` quando o comando fica só no teclado).
- `KeyBindings.pageKeys` é a tabela tecla → comando usada pelo PDF. Cada
  linha diz o que a tecla faz com zoom (`WhenZoomed`): o mesmo comando,
  deixar a rolagem para o PDFKit, ou outro comando (`scrollLeft`/`scrollRight`).
- `command(for:isZoomed:)` procura a tecla na tabela e devolve `nil` quando o
  PDFKit deve cuidar dela.
- `KeyBindings.open` é o ⌘O do menu File.

**`Views/KeyboardPDFView.swift`** — subclasse de `PDFView`.
- `perform(_:)` traduz cada comando para a API do PDFKit (`goToNextPage`,
  `zoomIn`…); "folha inteira" é `autoScales = true`.
- `keyDown(with:)` é chamado a cada tecla. Se a tabela tem um comando, executa;
  senão, chama `super.keyDown`, e o PDFKit faz o que faria normalmente.
- `scrollHorizontally(by:)` move a área visível: pega a `NSScrollView` que
  envolve a página, soma o deslocamento à origem do `clipView` (a "janela"
  sobre o conteúdo) e limita o valor entre a borda esquerda e a direita.

**`Views/ReaderController.swift`** — o menu vive fora das abas e não enxerga a
view do PDF. O controller guarda uma referência `weak` a ela; o
`ReaderWindowView` o publica com `focusedSceneValue` só quando a aba mostra um
PDF, e o menu o lê com `@FocusedValue`. É o mesmo mecanismo do `readerTab` do
step 03.

**`Views/ReaderCommands.swift`** — `CommandMenu("Go")` cria o menu Go, e
`CommandGroup(after: .toolbar)` adiciona os itens de zoom ao menu View. Cada
item chama `controller?.perform(...)`.

**`PDFReaderView`** cria `KeyboardPDFView` em vez de `PDFView` e entrega a
view ao controller.

## Conexão com o próximo step

O MVP está completo. A fase 2 começa pelos recursos de leitura de autos
(busca, índice por "Num.", copiar "Num. X - Pág. N"), que vão acrescentar
comandos ao `ReaderCommand` e atalhos ao `KeyBindings`.
