import SwiftUI

/// Lets the menus run commands on the PDF view of the focused tab.
final class ReaderController {
    weak var pdfView: KeyboardPDFView?

    func perform(_ command: ReaderCommand) {
        pdfView?.perform(command)
    }
}

extension FocusedValues {
    @Entry var readerController: ReaderController?
}
