//
//  FrictionLogApp.swift
//  FrictionLog
//
//  Created by Claude Code on 2026-01-29.
//

import SwiftUI

@main
struct FrictionLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // View menu commands
            CommandGroup(after: .sidebar) {
                Divider()
                Text("Switch View")
                    .disabled(true)
            }
        }
    }
}
