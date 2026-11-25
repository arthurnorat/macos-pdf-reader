import PDFKit

final class KeyboardPDFView: PDFView {

    private let horizontalScrollStep: CGFloat = 40

    func perform(_ command: ReaderCommand) {
        switch command {
        case .nextPage: goToNextPage(nil)
        case .previousPage: goToPreviousPage(nil)
        case .firstPage: goToFirstPage(nil)
        case .lastPage: goToLastPage(nil)
        case .zoomIn: zoomIn(nil)
        case .zoomOut: zoomOut(nil)
        case .fitPage: autoScales = true
        case .scrollLeft: scrollHorizontally(by: -horizontalScrollStep)
        case .scrollRight: scrollHorizontally(by: horizontalScrollStep)
        }
    }

    override func keyDown(with event: NSEvent) {
        if let command = KeyBindings.command(for: event, isZoomed: !autoScales) {
            perform(command)
        } else {
            super.keyDown(with: event)
        }
    }

    // PDFKit ignores ←/→ even when the page is wider than the window.
    private func scrollHorizontally(by delta: CGFloat) {
        guard let scrollView = documentView?.enclosingScrollView,
              let documentWidth = scrollView.documentView?.frame.width else { return }
        let clipView = scrollView.contentView
        let maxX = max(0, documentWidth - clipView.bounds.width)
        var origin = clipView.bounds.origin
        origin.x = min(max(origin.x + delta, 0), maxX)
        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
    }
}
