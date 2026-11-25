# PDF Reader for macOS

Simple, light, keyboard-first PDF reader for long court-case PDFs. The page
fills the window and everything is reachable from the keyboard. This file
refines `~/.claude/CLAUDE.md`; where they differ, this file prevails.

## Architecture
- SwiftUI app, macOS 14+, PDFKit for rendering. No external dependencies.
- Layers: Views -> ViewModels (`@Observable`) -> Services.
- Views contain no business logic. The PDFKit view is wrapped in an
  `NSViewRepresentable` (`PDFReaderView`) and subclassed
  (`KeyboardPDFView`) to own all key handling.
- All keyboard shortcuts live in a single file (`KeyBindings.swift`).
- Windows use `WindowGroup(for:)`, not `DocumentGroup`, so the same file can
  be open in several tabs. Each tab owns its own `PDFDocument`.
- Tabs are native macOS window tabs (`tabbingMode`), not a custom tab bar.
- Errors are typed: `enum AppError: Error` (`.fileNotFound`, `.notAPDF`,
  `.unreadable`). ViewModels expose a user-facing message.
- Privacy: the app has no network access (sandbox without the network
  entitlement) and no telemetry. Document content never leaves the machine.

## Verification (exception to the global rule)
Claude may build AND run this app on Arthur's Mac in this project.
- Build: `xcodebuild -scheme <Scheme> -destination 'platform=macOS' build`.
- Run and inspect the app on the Mac; Claude runs every verification case it
  can and reports what passed and what failed.
- Arthur runs the 1-3 cases most worth seeing in action, with the exact
  action, expected result and what a failure means.
- Never claim something was tested if it was not; say what was only built.
- Test PDFs live outside the repository. Never commit real case files.
- Five layers still apply (happy path, persistence, edge states, error path,
  regression). Edge states for this app: empty window, corrupted PDF,
  non-PDF file, one-page PDF, PDF with hundreds of pages.

## Out of scope
- `.pbxproj` files and build output (`DerivedData/`, `build/`).
- Sandbox and entitlements changes without asking.
- No automated tests for now (global rule).

## Infrastructure
None. Runs entirely on the local machine. No environment variables, no
external services.

## Steps
MVP (straight to `main`, one step at a time, stop after each):
1. `step-01-open-pdf`: window opens a PDF (open panel, drag, recents) in a
   `PDFView`; empty and error states. ADRs: `WindowGroup(for:)` over
   `DocumentGroup`; sandbox without network.
2. `step-02-reading-surface`: the default view is ONE FULL PAGE, page by
   page (`.singlePage` + `autoScales`): a portrait page fits the window from
   top to bottom, like Acrobat's "Zoom to Page Level" (requirement from
   Arthur, very important). Native full screen. Standard title bar and gray
   background (Arthur dropped the borderless-feel idea).
3. `step-03-tabs`: native tabs, same file open in two tabs.
4. `step-04-keyboard`: `KeyboardPDFView` and `KeyBindings.swift`.

Phase 2 (each its own step, detailed only after the MVP runs): search with
`/`, document indexer by "Num." with a side list, copy "Num. X - Pág. N"
(`y`/`Y`, double click on the footer), quick switcher and document jumps,
remember last position per file.

## Status
Current: step 02 done (verified by Arthur). Next: trim code comments, then
step 03.
Decided in step 01: name PDFReader, bundle id `com.arthurnorat.PDFReader`,
target macOS 14.0; PDF declared as a document type (Viewer, Alternate) in
`PDFReader/Info.plist`; recents via `NSDocumentController`.
Note for step 03: `WindowGroup(for: URL.self)` dedupes windows by value, so
the same file in two tabs needs a per-tab value (URL + UUID).
Open decisions to confirm with Arthur before the step that needs them:
- Vim-style keys (`j`/`k`/`g`/`G`) in addition to the macOS ones (before
  step 04).
