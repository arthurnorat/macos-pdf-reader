import Foundation
import Observation
import PDFKit

@Observable
final class ReaderViewModel {

    enum State {
        case empty
        case loaded(PDFDocument)
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
