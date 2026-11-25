# Step 03 — Abas

## Objetivo

Abrir os arquivos como **abas nativas** do macOS numa mesma janela, inclusive
o mesmo arquivo em várias abas, cada uma com navegação própria.

## Decisões

**Sempre abrir em aba.** O macOS só usa abas quando o usuário escolhe isso
nos Ajustes do Sistema (o padrão é "só em tela cheia"). Para um leitor de
autos, abas são o comportamento esperado, então o app força
`tabbingMode = .preferred` em cada janela.

**Abrir de novo cria outra aba.** A alternativa era trazer para frente a aba
que já mostra o arquivo. Criar outra aba é mais simples de entender e permite
comparar duas partes do mesmo PDF. Cada aba nova começa na página 1.

**`ReaderTab` com `UUID` como valor da janela.** O `WindowGroup(for:)` trata
valores iguais como a mesma janela. Com `URL`, o mesmo arquivo nunca abria
duas vezes. Com um `id` novo a cada abertura, os valores são sempre
diferentes e cada abertura vira uma aba.

**Chegar ao `NSWindow` por uma view AppKit invisível.** O SwiftUI não tem API
para abas de janela. Uma `NSView` sem conteúdo, colocada no fundo da tela,
recebe o aviso de que entrou numa janela (`viewDidMoveToWindow`) e configura
essa janela.

## Como o código funciona

**`Models/ReaderTab.swift`** — `id` (`UUID`) + `url`. É `Hashable` (o
`WindowGroup` compara valores) e `Codable` (o macOS salva e restaura as abas
ao reabrir o app).

**`Views/WindowTabbing.swift`** — o `NSViewRepresentable` invisível que faz
`window.tabbingMode = .preferred`. Aplicado em `ReaderWindowView` com
`.background(WindowTabbing())`.

**`PDFReaderApp`, `ReaderWindowView`, `WindowRouter`, `FileCommands`** —
trocam `URL?` por `ReaderTab?`. O router cria `ReaderTab(url:)` ao preencher
uma aba vazia ou ao abrir uma nova. O ViewModel e os Services não mudam:
continuam recebendo só a `URL`.

**`onOpenURL` com `DispatchQueue.main.async`** — depois de entregar um
arquivo vindo do Finder, o SwiftUI traz para frente a janela que o recebeu.
Abrir a aba nova na volta seguinte do *run loop* (o ciclo em que o app
processa eventos) faz ela abrir por último e ficar selecionada.

Vêm prontos do macOS, sem código: a barra de abas, o botão **+**, arrastar
uma aba para fora (vira janela) e *Window › Merge All Windows*.

## Conexão com o próximo step

O step 04 concentra o teclado: `KeyboardPDFView` e `KeyBindings.swift`, com
os atalhos de página, zoom e abas num único lugar.
