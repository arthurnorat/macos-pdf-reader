import AppKit
import Observation

/// The list behind File > Open Recent.
///
/// The real storage is macOS's own recent-documents list, kept by
/// `NSDocumentController`. That class is not observable, so SwiftUI would
/// never notice a change. This service mirrors the list in an `@Observable`
/// property: when a file is added or the list is cleared, the menu rebuilds.
///
/// It is a single shared instance because the list it wraps is also a single
/// shared list, the same for every window.
@Observable
final class RecentDocumentsService {

    static let shared = RecentDocumentsService()

    private(set) var urls: [URL]

    private let controller = NSDocumentController.shared

    private init() {
        urls = controller.recentDocumentURLs
    }

    /// Records a file that was opened successfully.
    func add(_ url: URL) {
        controller.noteNewRecentDocumentURL(url)
        urls = controller.recentDocumentURLs
    }

    func clear() {
        controller.clearRecentDocuments(nil)
        urls = controller.recentDocumentURLs
    }
}
