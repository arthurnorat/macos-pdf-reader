import SwiftUI

struct WindowRouter {

    let openWindow: OpenWindowAction

    /// Puts the first file into `current` if that window is empty; opens the
    /// others in new windows. Pass `nil` when no window made the request.
    func open(_ urls: [URL], into current: Binding<URL?>?) {
        var remaining = urls[...]

        if let current, current.wrappedValue == nil, let first = remaining.popFirst() {
            current.wrappedValue = first
        }

        for url in remaining {
            // Brings an existing window with the same URL to the front
            // instead of opening a duplicate.
            openWindow(value: url)
        }
    }
}

extension FocusedValues {
    @Entry var documentURL: Binding<URL?>?
}
