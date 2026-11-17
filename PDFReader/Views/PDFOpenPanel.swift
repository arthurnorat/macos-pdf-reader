import AppKit
import UniformTypeIdentifiers

/// The system "Open" panel, limited to PDFs.
///
/// `NSOpenPanel` (AppKit) is used instead of SwiftUI's `.fileImporter`
/// because File > Open… must work even when no window is open, and
/// `.fileImporter` needs a view to be attached to.
///
/// Sandbox: the user's choice in this panel is what grants the app
/// permission to read the chosen files (the "user-selected files"
/// entitlement, read-only).
enum PDFOpenPanel {

    /// Shows the panel and returns the chosen files (empty if cancelled).
    static func choosePDFs() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.urls : []
    }
}
