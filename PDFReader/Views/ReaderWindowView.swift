import SwiftUI

/// The content of one reader window: the empty screen, the PDF, or an error.
///
/// `url` comes from `WindowGroup(for: URL.self)`: it is the value that
/// identifies this window. Changing it (for example, after choosing a file in
/// the empty screen) makes the ViewModel load the new file.
struct ReaderWindowView: View {

    @Binding var url: URL?

    @State private var viewModel = ReaderViewModel()
    @Environment(\.openWindow) private var openWindow

    private var router: WindowRouter { WindowRouter(openWindow: openWindow) }

    var body: some View {
        content
            // Fill the whole window and make every point of it hit-testable.
            // Without this, the empty and error screens only react where
            // something is drawn (icon, text, button): a file dropped on the
            // transparent area around them is refused and bounces back.
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity)
            .contentShape(Rectangle())
            .navigationTitle(url?.lastPathComponent ?? "PDFReader")
            .onChange(of: url, initial: true) {
                viewModel.load(url)
            }
            .dropDestination(for: URL.self) { droppedURLs, _ in
                router.open(droppedURLs, into: $url)
                return true
            }
            .onOpenURL { openedURL in
                // Files opened from the Finder or the Dock icon arrive here.
                router.open([openedURL], into: $url)
            }
            // By default SwiftUI creates a brand-new window for every file
            // opened from the Finder and delivers the URL there. That empty
            // window would take the file directly, skipping the "already
            // open?" check of `openWindow(value:)`, and the same file would
            // end up in two windows. "*" makes an existing window receive
            // the event instead, so it always goes through the router.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
            .focusedSceneValue(\.documentURL, $url)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .empty:
            ContentUnavailableView {
                Label("No PDF Open", systemImage: "doc.richtext")
            } description: {
                Text("Open a PDF or drag one into this window.")
            } actions: {
                openButton
            }

        case .loaded(let document):
            PDFReaderView(document: document)

        case .failed(let message):
            ContentUnavailableView {
                Label("Can't Open This File", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                openButton
            }
        }
    }

    private var openButton: some View {
        Button("Open…") {
            // In the error state the window already has a (bad) URL, so the
            // router would open a new window. Clearing it first makes the
            // chosen file replace the failed one in this same window.
            if case .failed = viewModel.state { url = nil }
            router.open(PDFOpenPanel.choosePDFs(), into: $url)
        }
    }
}
