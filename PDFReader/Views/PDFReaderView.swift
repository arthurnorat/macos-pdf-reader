import PDFKit
import SwiftUI

/// Bridges PDFKit's `PDFView` (an AppKit `NSView`) into SwiftUI.
///
/// SwiftUI has no native PDF view. `NSViewRepresentable` is the adapter:
/// SwiftUI calls `makeNSView` once to create the AppKit view, and
/// `updateNSView` every time the inputs (`document`) change.
///
/// For now it uses PDFKit's default settings. Zoom and layout come in
/// step 02; keyboard handling (`KeyboardPDFView`) in step 04.
struct PDFReaderView: NSViewRepresentable {

    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        // PDFView registers itself as a drag destination and refuses file
        // drops, so they never reach SwiftUI's `.dropDestination`. Removing
        // the registration lets the drop fall through to the window, where
        // the router decides what to do with the file.
        pdfView.unregisterDraggedTypes()
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // `!==` compares identity (same object), not content. Reassigning
        // the same document would reset the scroll position for nothing.
        if pdfView.document !== document {
            pdfView.document = document
        }
    }
}
