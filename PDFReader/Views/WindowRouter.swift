import SwiftUI

struct WindowRouter {

    let openWindow: OpenWindowAction

    /// Puts the first file into `current` if that window is empty; opens the
    /// others in new tabs. Pass `nil` when no window made the request.
    func open(_ urls: [URL], into current: Binding<ReaderTab?>?) {
        var remaining = urls[...]

        if let current, current.wrappedValue == nil, let first = remaining.popFirst() {
            current.wrappedValue = ReaderTab(url: first)
        }

        for url in remaining {
            openWindow(value: ReaderTab(url: url))
        }
    }
}

extension FocusedValues {
    @Entry var readerTab: Binding<ReaderTab?>?
}
