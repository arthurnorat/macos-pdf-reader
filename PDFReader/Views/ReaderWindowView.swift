import SwiftUI

struct ReaderWindowView: View {

    @Binding var tab: ReaderTab?

    @State private var viewModel = ReaderViewModel()
    @State private var controller = ReaderController()
    @Environment(\.openWindow) private var openWindow

    private var router: WindowRouter { WindowRouter(openWindow: openWindow) }

    private var showsPDF: Bool {
        if case .loaded = viewModel.state { true } else { false }
    }

    var body: some View {
        content
            // Accept drops on the whole window, not only on drawn content.
            .frame(minWidth: 480, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background(WindowTabbing())
            .navigationTitle(tab?.url.lastPathComponent ?? "PDFReader")
            .onChange(of: tab, initial: true) {
                viewModel.load(tab?.url)
            }
            .dropDestination(for: URL.self) { droppedURLs, _ in
                router.open(droppedURLs, into: $tab)
                return true
            }
            .onOpenURL { openedURL in
                // SwiftUI brings this window to the front after the handler
                // returns; open on the next run loop so the new tab stays selected.
                DispatchQueue.main.async {
                    router.open([openedURL], into: $tab)
                }
            }
            // Deliver Finder opens to an existing window; otherwise SwiftUI
            // creates a new one and an empty window is left behind.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
            .focusedSceneValue(\.readerTab, $tab)
            .focusedSceneValue(\.readerController, showsPDF ? controller : nil)
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
            PDFReaderView(document: document, controller: controller)

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
            if case .failed = viewModel.state { tab = nil }
            router.open(PDFOpenPanel.choosePDFs(), into: $tab)
        }
    }
}
