//
//  FrictionLogApp.swift
//  FrictionLog
//
//  Created by Claude Code on 2026-01-29.
//

import SwiftUI
import UserNotifications

@main
struct FrictionLogApp: App {
    init() {
        requestNotificationPermissions()
    }

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

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
