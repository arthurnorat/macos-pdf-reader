import PDFKit
import SwiftUI

/// Bridges PDFKit's `PDFView` (an AppKit `NSView`) into SwiftUI.
///
/// SwiftUI has no native PDF view. `NSViewRepresentable` is the adapter:
/// SwiftUI calls `makeNSView` once to create the AppKit view, and
/// `updateNSView` every time the inputs (`document`) change.
///
/// Keyboard handling (`KeyboardPDFView`) comes in step 04.
struct PDFReaderView: NSViewRepresentable {

    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        // One full sheet at a time (step 02): `.singlePage` shows exactly one
        // page, and `autoScales` keeps the zoom at the size where that whole
        // page fits the visible area — recalculated on every resize and in
        // full screen. A portrait page is limited by the height, so it fills
        // the window from top to bottom.
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
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
