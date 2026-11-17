import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Turns a file URL into a `PDFDocument`, or into a typed `AppError`.
///
/// The checks run from the cheapest to the most expensive, so each failure
/// gets the most precise error:
/// 1. Does the file exist?            -> `.fileNotFound`
/// 2. Is it a PDF (by its type)?      -> `.notAPDF`
/// 3. Can PDFKit actually open it?    -> `.unreadable`
struct DocumentService {

    func loadDocument(at url: URL) throws(AppError) -> PDFDocument {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw .fileNotFound
        }

        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.contentTypeKey])
        } catch {
            // The file exists but its metadata cannot be read (for example,
            // no permission). From the user's side the file cannot be opened.
            throw .unreadable
        }

        guard let contentType = values.contentType, contentType.conforms(to: .pdf) else {
            throw .notAPDF
        }

        // `PDFDocument(url:)` returns nil when the bytes are not a valid PDF,
        // even if the name ends in ".pdf".
        guard let document = PDFDocument(url: url) else {
            throw .unreadable
        }

        // A PDF locked with a user password, or one with zero pages, opens
        // but has nothing to show.
        guard !document.isLocked, document.pageCount > 0 else {
            throw .unreadable
        }

        return document
    }
}
