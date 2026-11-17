import Foundation

/// Every failure the app can report to the user.
///
/// The cases describe *what went wrong from the user's point of view*, not
/// which API failed. The user-facing text for each case lives in the
/// ViewModel, which is the layer that talks to the screen.
enum AppError: Error, Equatable {
    /// The file no longer exists at that location (moved, renamed, deleted).
    case fileNotFound
    /// The file exists but is not a PDF (for example a .docx or an image).
    case notAPDF
    /// The file claims to be a PDF but PDFKit cannot read it
    /// (corrupted, truncated, password-protected or without pages).
    case unreadable
}
