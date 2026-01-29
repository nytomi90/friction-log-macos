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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permissions granted")
            } else {
                print("⚠️ Notification permissions denied by user")
            }
        }
    }
}
