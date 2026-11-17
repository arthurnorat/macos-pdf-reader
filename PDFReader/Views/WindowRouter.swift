import SwiftUI

/// Decides *which window* shows each file that arrives — from the Open
/// panel, a drop, Open Recent, or the Finder.
///
/// The rule is the same everywhere:
/// - if the current window is still empty, the first file goes into it;
/// - every other file opens in a new window.
///
/// This avoids leaving an empty window behind after opening a file.
struct WindowRouter {

    let openWindow: OpenWindowAction

    /// - Parameters:
    ///   - urls: the files to open, in order.
    ///   - current: the URL of the window that received the request, or
    ///     `nil` when the request does not come from a window (for example,
    ///     File > Open… with every window closed).
    func open(_ urls: [URL], into current: Binding<URL?>?) {
        var remaining = urls[...]

        if let current, current.wrappedValue == nil, let first = remaining.popFirst() {
            current.wrappedValue = first
        }

        for url in remaining {
            // WindowGroup(for: URL.self) creates a window for this value.
            // If a window with the same URL already exists, SwiftUI brings
            // that window to the front instead of creating a second one.
            openWindow(value: url)
        }
    }
}

extension FocusedValues {
    /// The URL of the focused reader window, published by each window so
    /// the menu commands know where to open files.
    @Entry var documentURL: Binding<URL?>?
}
