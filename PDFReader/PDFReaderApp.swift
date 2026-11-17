//
//  PDFReaderApp.swift
//  PDFReader
//
//  Created by Arthur Norat on 14/11/26.
//

import SwiftUI

@main
struct PDFReaderApp: App {
    var body: some Scene {
        // One window per value: each window is identified by the URL of the
        // PDF it shows (`nil` for an empty window). See step 01's ADR for
        // why this is not a DocumentGroup.
        WindowGroup(for: URL.self) { $url in
            ReaderWindowView(url: $url)
        }
        .commands {
            FileCommands()
        }
    }
}
