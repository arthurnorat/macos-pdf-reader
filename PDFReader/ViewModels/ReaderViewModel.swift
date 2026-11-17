import Foundation
import Observation
import PDFKit

/// State of one reader window.
///
/// Each window owns its own ViewModel, so each window owns its own
/// `PDFDocument`. The View only reads `state` and calls `load(_:)`; it never
/// talks to the services directly.
@Observable
final class ReaderViewModel {

    enum State {
        /// No file in this window yet: show the "Open…" screen.
        case empty
        /// A PDF was loaded and is ready to be displayed.
        case loaded(PDFDocument)
        /// Loading failed; `message` is ready to be shown to the user.
        case failed(message: String)
    }

    private(set) var state: State = .empty

    private let documentService: DocumentService
    private let recents: RecentDocumentsService

    init(
        documentService: DocumentService = DocumentService(),
        recents: RecentDocumentsService = .shared
    ) {
        self.documentService = documentService
        self.recents = recents
    }

    /// Loads the file this window points to. `nil` means "no file".
    func load(_ url: URL?) {
        guard let url else {
            state = .empty
            return
        }

        do {
            let document = try documentService.loadDocument(at: url)
            state = .loaded(document)
            recents.add(url)
        } catch {
            // Typed throws: `error` is an `AppError`, so the switch below is
            // checked by the compiler for every case.
            state = .failed(message: Self.message(for: error, fileName: url.lastPathComponent))
        }
    }

    static func message(for error: AppError, fileName: String) -> String {
        switch error {
        case .fileNotFound:
            "“\(fileName)” could not be found. It may have been moved, renamed or deleted."
        case .notAPDF:
            "“\(fileName)” is not a PDF file."
        case .unreadable:
            "“\(fileName)” could not be read. The file may be damaged or password-protected."
        }
    }
}
