import SwiftUI

struct ReaderWindowView: View {

    @Binding var url: URL?

    @State private var viewModel = ReaderViewModel()
    @Environment(\.openWindow) private var openWindow

    private var router: WindowRouter { WindowRouter(openWindow: openWindow) }

    var body: some View {
        content
            // Accept drops on the whole window, not only on drawn content.
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
                router.open([openedURL], into: $url)
            }
            // Deliver Finder opens to an existing window; otherwise SwiftUI
            // creates a new empty one and the same file opens twice.
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
            // Replace the failed file in this window instead of opening a new one.
            if case .failed = viewModel.state { url = nil }
            router.open(PDFOpenPanel.choosePDFs(), into: $url)
        }
    }
}
