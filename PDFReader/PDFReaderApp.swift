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
        WindowGroup(for: ReaderTab.self) { $tab in
            ReaderWindowView(tab: $tab)
        }
        .commands {
            FileCommands()
        }
    }
}
