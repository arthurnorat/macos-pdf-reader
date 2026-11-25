import AppKit
import UniformTypeIdentifiers

/// Uses `NSOpenPanel` rather than `.fileImporter` because File > Open… must
/// work when no window is open.
enum PDFOpenPanel {

    /// Returns the chosen files, or an empty array if the user cancels.
    static func choosePDFs() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.urls : []
    }
}
