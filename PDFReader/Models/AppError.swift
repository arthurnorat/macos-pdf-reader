import Foundation

enum AppError: Error, Equatable {
    case fileNotFound
    case notAPDF
    /// Corrupted, password-protected or without pages.
    case unreadable
}
