import PDFKit
import SwiftUI

struct PDFReaderView: NSViewRepresentable {

    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.document = document
        // PDFView refuses file drops; let them reach SwiftUI's dropDestination.
        pdfView.unregisterDraggedTypes()
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Reassigning the same document would send the reader back to page 1.
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
}
