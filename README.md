🇺🇸 [English](#english) · 🇧🇷 [Português](#português)

---

<a name="english"></a>

# PDFReader

A simple, light, keyboard-first PDF reader for macOS, made for long
court-case PDFs. Built with SwiftUI and PDFKit, with no external
dependencies.

**Privacy:** the app runs in the App Sandbox with no network access and no
telemetry. Documents never leave your Mac.

## Features

- Open a PDF from **File › Open…** (⌘O), **File › Open Recent**, by dragging
  it into a window, or from the Finder (double-click, *Open With*, or
  dropping it on the Dock icon).
- Files open as tabs in the same window; the same file can be open in
  several tabs. An empty tab is reused for the next file you open.
- Clear error messages for missing files, files that are not PDFs, and
  damaged or password-protected PDFs.
- One full page at a time: each page fits the window from top to bottom and
  stays whole when you resize the window. Scroll or press Page Down to turn
  the page.
- Full screen (⌃⌘F or the green window button).

## Requirements

- macOS 14 or later
- Xcode 26 or later to build

## Build and run

Open `PDFReader.xcodeproj` in Xcode and press ⌘R, or build from the terminal:

```bash
xcodebuild -scheme PDFReader -destination 'platform=macOS' build
```

## Documentation

Step-by-step study notes (in Portuguese) live in [`docs/steps/`](docs/steps/).

---

<a name="português"></a>

# PDFReader

Um leitor de PDF para macOS simples, leve e pensado para o teclado, feito
para PDFs longos de processos judiciais. Construído com SwiftUI e PDFKit,
sem dependências externas.

**Privacidade:** o app roda no App Sandbox, sem acesso à rede e sem
telemetria. Os documentos nunca saem do seu Mac.

## Funcionalidades

- Abra um PDF por **File › Open…** (⌘O), **File › Open Recent**, arrastando
  para uma janela ou pelo Finder (duplo clique, *Abrir com* ou soltando no
  ícone do Dock).
- Os arquivos abrem como abas na mesma janela; o mesmo arquivo pode estar
  aberto em várias abas. Uma aba vazia é reaproveitada para o próximo
  arquivo aberto.
- Mensagens de erro claras para arquivo não encontrado, arquivo que não é
  PDF e PDF danificado ou protegido por senha.
- Uma folha inteira por vez: cada página ocupa a janela de cima a baixo e
  continua inteira ao redimensionar a janela. Role ou aperte Page Down para
  virar a página.
- Tela cheia (⌃⌘F ou o botão verde da janela).

## Requisitos

- macOS 14 ou superior
- Xcode 26 ou superior para compilar

## Compilar e executar

Abra `PDFReader.xcodeproj` no Xcode e aperte ⌘R, ou compile pelo terminal:

```bash
xcodebuild -scheme PDFReader -destination 'platform=macOS' build
```

## Documentação

As notas de estudo de cada step (em português) ficam em
[`docs/steps/`](docs/steps/).
