import PDFKit

/// A page that never reports detected data (phone numbers, links, dates),
/// so PDFKit shows no hover box, tooltip or tel: link over the text.
nonisolated final class QuietPDFPage: PDFPage {
    // Private PDFKit hooks: if Apple renames them, they just stop matching.
    @objc(pdfScannerResultAtPoint:)
    func noScannerResult(at point: NSPoint) -> AnyObject? { nil }

    @objc(pdfScannerResultAtPoint:onPageLayer:)
    func noScannerResult(at point: NSPoint, onPageLayer layer: AnyObject?) -> AnyObject? { nil }

    @objc(addDetectedAnnotations:)
    func ignoreDetectedAnnotations(_ annotations: AnyObject?) {}

    @objc(detectedAnnotations)
    func noDetectedAnnotations() -> NSArray { [] }
}

/// Makes a `PDFDocument` build its pages as `QuietPDFPage`.
nonisolated final class QuietPageProvider: NSObject, PDFDocumentDelegate {
    func classForPage() -> AnyClass { QuietPDFPage.self }
}
