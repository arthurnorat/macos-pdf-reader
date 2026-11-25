import SwiftUI

struct FileCommands: Commands {

    @FocusedValue(\.readerTab) private var focusedTab
    @Environment(\.openWindow) private var openWindow

    private let recents = RecentDocumentsService.shared

    private var router: WindowRouter { WindowRouter(openWindow: openWindow) }

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open…") {
                router.open(PDFOpenPanel.choosePDFs(), into: focusedTab)
            }
            .keyboardShortcut("o")

            Menu("Open Recent") {
                ForEach(recents.urls, id: \.self) { url in
                    Button(url.lastPathComponent) {
                        router.open([url], into: focusedTab)
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
