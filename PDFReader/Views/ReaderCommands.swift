import SwiftUI

struct ReaderCommands: Commands {

    @FocusedValue(\.readerController) private var controller

    var body: some Commands {
        CommandMenu("Go") {
            item(.nextPage)
            item(.previousPage)
            Divider()
            item(.firstPage)
            item(.lastPage)
        }

        CommandGroup(after: .toolbar) {
            item(.zoomIn)
            item(.zoomOut)
            item(.fitPage)
            Divider()
        }
    }

    private func item(_ command: ReaderCommand) -> some View {
        Button(command.title) {
            controller?.perform(command)
        }
        .keyboardShortcut(command.menuShortcut)
        .disabled(controller == nil)
    }
}
