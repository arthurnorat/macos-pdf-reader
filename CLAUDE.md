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

Tooling (before Phase 2, each its own step):
5. `step-05-ci`: GitHub Actions building the app on every push.
6. `step-06-lint-format`: SwiftLint and SwiftFormat.

Phase 2 (in this order; each detailed only when it starts; ask Arthur
whether a step needs its own branch):
7. `step-07-copy-num`: copy "Num. X - Pág. N" of the current page (shortcut
   and double click on the footer to be decided); builds the footer parser.
8. `step-08-document-index`: side list of documents by "Num." (reuses the
   parser).
9. `step-09-document-jumps`: next/previous document and quick switcher.
10. `step-10-search`: text search.
11. `step-11-remember-position`: reopen each file on its last page
    (security-scoped bookmarks: sandbox entitlement change, ask first).

## Status
Current: step 04 done (verified by Arthur); the MVP is complete. Next:
step 05 (CI).
Decided in step 01: name PDFReader, bundle id `com.arthurnorat.PDFReader`,
target macOS 14.0; PDF declared as a document type (Viewer, Alternate) in
`PDFReader/Info.plist`; recents via `NSDocumentController`.
Decided in step 03: every file opens as a new tab (`tabbingMode = .preferred`);
reopening a file creates another tab; window value is `ReaderTab` (URL + UUID).
Decided in step 04: macOS keys only (no Vim); shortcuts shown in Go/View
menus (only ⌘ shortcuts; bare keys in a menu would bypass the zoom logic);
when zoomed in, arrows, Space and Page Up/Down scroll instead of turning the
page.
