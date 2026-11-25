import AppKit
import SwiftUI

enum ReaderCommand: CaseIterable {
    case nextPage, previousPage, firstPage, lastPage
    case zoomIn, zoomOut, fitPage
    case scrollLeft, scrollRight

    var title: String {
        switch self {
        case .nextPage: "Next Page"
        case .previousPage: "Previous Page"
        case .firstPage: "First Page"
        case .lastPage: "Last Page"
        case .zoomIn: "Zoom In"
        case .zoomOut: "Zoom Out"
        case .fitPage: "Fit Page"
        case .scrollLeft: "Scroll Left"
        case .scrollRight: "Scroll Right"
        }
    }

    /// Keys without ⌘ stay out of the menu: a menu shortcut catches the key
    /// before `KeyboardPDFView`, which needs it to scroll when zoomed in.
    var menuShortcut: KeyboardShortcut? {
        switch self {
        case .nextPage, .previousPage: nil
        case .firstPage: KeyboardShortcut(.upArrow, modifiers: .command)
        case .lastPage: KeyboardShortcut(.downArrow, modifiers: .command)
        case .zoomIn: KeyboardShortcut("+", modifiers: .command)
        case .zoomOut: KeyboardShortcut("-", modifiers: .command)
        case .fitPage: KeyboardShortcut("0", modifiers: .command)
        case .scrollLeft, .scrollRight: nil
        }
    }
}

enum KeyBindings {

    static let open = KeyboardShortcut("o", modifiers: .command)

    private enum Key: Equatable {
        case special(NSEvent.SpecialKey)
        case character(String)
    }

    /// What a key does while the page is zoomed in.
    private enum WhenZoomed {
        case same
        case pdfKitScrolls
        case run(ReaderCommand)
    }

    private struct Binding {
        let key: Key
        let modifiers: NSEvent.ModifierFlags
        let command: ReaderCommand
        var whenZoomed: WhenZoomed = .same
    }

    /// Keys handled by the PDF view. Shortcuts with ⌘ reach the menu first.
    private static let pageKeys: [Binding] = [
        Binding(key: .special(.rightArrow), modifiers: [], command: .nextPage, whenZoomed: .run(.scrollRight)),
        Binding(key: .special(.downArrow), modifiers: [], command: .nextPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .special(.pageDown), modifiers: [], command: .nextPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .character(" "), modifiers: [], command: .nextPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .special(.leftArrow), modifiers: [], command: .previousPage, whenZoomed: .run(.scrollLeft)),
        Binding(key: .special(.upArrow), modifiers: [], command: .previousPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .special(.pageUp), modifiers: [], command: .previousPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .character(" "), modifiers: .shift, command: .previousPage, whenZoomed: .pdfKitScrolls),
        Binding(key: .special(.home), modifiers: [], command: .firstPage),
        Binding(key: .special(.upArrow), modifiers: .command, command: .firstPage),
        Binding(key: .special(.end), modifiers: [], command: .lastPage),
        Binding(key: .special(.downArrow), modifiers: .command, command: .lastPage),
    ]

    /// Returns `nil` when the key should keep PDFKit's own behavior.
    static func command(for event: NSEvent, isZoomed: Bool) -> ReaderCommand? {
        // Arrow keys also carry the .function and .numericPad flags; ignore them.
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key: Key = event.specialKey.map { .special($0) }
            ?? .character(event.charactersIgnoringModifiers ?? "")
        guard let binding = pageKeys.first(where: { $0.key == key && $0.modifiers == modifiers }) else {
            return nil
        }
        guard isZoomed else { return binding.command }
        switch binding.whenZoomed {
        case .same: return binding.command
        case .pdfKitScrolls: return nil
        case .run(let command): return command
        }
    }
}
