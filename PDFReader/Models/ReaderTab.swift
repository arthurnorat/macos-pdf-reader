import Foundation

/// The value that identifies a window. The `id` makes every opening unique,
/// so the same file can be open in several tabs.
struct ReaderTab: Hashable, Codable {
    var id = UUID()
    var url: URL
}
