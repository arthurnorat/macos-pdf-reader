import AppKit
import Observation

/// Mirrors `NSDocumentController`'s recent list, which is not observable,
/// so the Open Recent menu updates when it changes.
@Observable
final class RecentDocumentsService {

    static let shared = RecentDocumentsService()

    private(set) var urls: [URL]

    private let controller = NSDocumentController.shared

    private init() {
        urls = controller.recentDocumentURLs
    }

    func add(_ url: URL) {
        controller.noteNewRecentDocumentURL(url)
        urls = controller.recentDocumentURLs
    }

    func clear() {
        controller.clearRecentDocuments(nil)
        urls = controller.recentDocumentURLs
    }
}
