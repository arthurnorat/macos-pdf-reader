import Foundation
import PDFKit
import UniformTypeIdentifiers

struct DocumentService {

    // `PDFDocument.delegate` is weak, so the provider must be kept alive here.
    private let pageProvider = QuietPageProvider()

    func loadDocument(at url: URL) throws(AppError) -> PDFDocument {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw .fileNotFound
        }

        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.contentTypeKey])
        } catch {
            throw .unreadable
        }

        guard let contentType = values.contentType, contentType.conforms(to: .pdf) else {
            throw .notAPDF
        }

        guard let document = PDFDocument(url: url) else {
            throw .unreadable
        }
        document.delegate = pageProvider

        guard !document.isLocked, document.pageCount > 0 else {
            throw .unreadable
        }

        return document
    }
}
