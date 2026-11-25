import AppKit
import SwiftUI

/// Makes the hosting window open as a tab. SwiftUI has no API for this, so
/// it reaches the `NSWindow` through an invisible AppKit view.
struct WindowTabbing: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView {
        TabbingView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class TabbingView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.tabbingMode = .preferred
        }
    }
}
