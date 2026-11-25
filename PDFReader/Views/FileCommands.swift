import SwiftUI

struct FileCommands: Commands {

    @FocusedValue(\.documentURL) private var focusedDocumentURL
    @Environment(\.openWindow) private var openWindow

    private let recents = RecentDocumentsService.shared

    private var router: WindowRouter { WindowRouter(openWindow: openWindow) }

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open…") {
                router.open(PDFOpenPanel.choosePDFs(), into: focusedDocumentURL)
            }
            .keyboardShortcut("o")

            Menu("Open Recent") {
                ForEach(recents.urls, id: \.self) { url in
                    Button(url.lastPathComponent) {
                        router.open([url], into: focusedDocumentURL)
                    }
                }

                Divider()

                Button("Clear Menu") {
                    recents.clear()
                }
                .disabled(recents.urls.isEmpty)
            }
        }
    }
}
