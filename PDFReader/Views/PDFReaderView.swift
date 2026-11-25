import PDFKit
import SwiftUI

struct PDFReaderView: NSViewRepresentable {

    let document: PDFDocument
    let controller: ReaderController

    func makeNSView(context: Context) -> KeyboardPDFView {
        let pdfView = KeyboardPDFView()
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.document = document
        // PDFView refuses file drops; let them reach SwiftUI's dropDestination.
        pdfView.unregisterDraggedTypes()
        controller.pdfView = pdfView
        return pdfView
    }

    func updateNSView(_ pdfView: KeyboardPDFView, context: Context) {
        // Reassigning the same document would send the reader back to page 1.
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
}
