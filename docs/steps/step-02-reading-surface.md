# Step 02 — Superfície de leitura: uma folha inteira por vez

## Objetivo

Mostrar os autos como eles são lidos: **uma folha inteira por vez**. Uma
página em pé ocupa a janela de cima a baixo, como o "Zoom to Page Level" do
Acrobat, e continua inteira ao redimensionar a janela ou em tela cheia.

## Decisões

**Página por página, não rolagem contínua.**

| Opção | Ganha | Custa |
|---|---|---|
| `.singlePage` (escolhida) | Sempre uma folha inteira, sem pedaços de outras; o PDFKit já encaixa a página. | Folhear muitas páginas é "aos saltos". |
| Rolagem contínua com zoom pela altura | Rolagem fluida. | Meias páginas na tela; zoom calculado à mão a cada redimensionamento. |

**`autoScales` em vez de calcular o zoom à mão.** O PDFKit calcula o zoom
que encaixa a página e o recalcula sozinho quando a janela muda de tamanho.
O custo: um zoom com pinça desliga o `autoScales`; voltar à folha inteira
será um atalho do step 04.

**Barra de título padrão.** As alternativas (barra escondida ou
transparente) só mudavam a aparência. A folha inteira não depende delas,
então ficou a opção mais simples, com o nome do arquivo sempre visível.

**Tela cheia nativa, sem código.** O `WindowGroup` já oferece o botão verde,
o ⌃⌘F e *View › Enter Full Screen*, e o `autoScales` mantém a folha inteira
também em tela cheia.

## Como o código funciona

A única mudança está em `PDFReader/Views/PDFReaderView.swift`:

```swift
pdfView.displayMode = .singlePage
pdfView.autoScales = true
```

- **`displayMode = .singlePage`** mostra uma página por vez. Rolagem, Page
  Down e as setas verticais viram a página; esse comportamento vem dos
  atalhos padrão do macOS, que o `PDFView` já entende.
- **`autoScales = true`** usa o maior zoom em que a página inteira cabe:
  `min(largura disponível ÷ largura da página, altura disponível ÷ altura da página)`.
  Numa janela de monitor (mais larga que alta), quem limita é a altura, e a
  folha vai de cima a baixo.

As duas linhas vêm antes de `pdfView.document = document`, para o PDF já ser
desenhado na forma final. A configuração fica na View porque é apresentação:
o ViewModel decide **qual** documento mostrar; a View decide **como**.

## Conexão com o próximo step

O step 03 traz as abas nativas do macOS e permite abrir o mesmo arquivo em
duas abas, trocando o valor de cada janela de `URL` para URL + `UUID`.
