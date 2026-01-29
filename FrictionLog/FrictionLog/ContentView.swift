//
//  ContentView.swift
//  FrictionLog
//
//  Main content view with tab navigation
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = FrictionViewModel()
    @State private var selectedTab = 0
    @State private var showHelp = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selectedTab) {
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(0)

                FrictionListView(viewModel: viewModel)
                    .tabItem {
                        Label("My Frictions", systemImage: "list.bullet")
                    }
                    .tag(1)

                AddFrictionView(viewModel: viewModel)
                    .tabItem {
                        Label("Add New", systemImage: "plus.circle.fill")
                    }
                    .tag(2)
            }

            // Help and Test Buttons
            HStack(spacing: 8) {
                // Test Notification button
                Button {
                    testNotification()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 32, height: 32)

                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
                .buttonStyle(.plain)
                .help("Test notifications")

                // Help button
                Button {
                    showHelp = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)

                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
                .help("Learn how to use Friction Log")
            }
            .padding(16)
        }
        .frame(minWidth: 900, minHeight: 700)
        .sheet(isPresented: $showHelp) {
            HelpSheet(isPresented: $showHelp)
        }
    }

    private func testNotification() {
        print("🔔 Testing notification...")
        let content = UNMutableNotificationContent()
        content.title = "🔔 Test Notification"
        content.body = "If you see this, notifications are working! You'll receive alerts when approaching your daily friction limit."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "test-notification-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send test notification: \(error.localizedDescription)")
            } else {
                print("✅ Test notification sent successfully")
            }
        }
    }
}

// MARK: - Help Sheet

struct HelpSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📚 How to Use Friction Log")
                        .font(.title2)
                        .bold()
                    Text("Your guide to tracking and eliminating daily frictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(
                        emoji: "❓",
                        title: "What is a Friction?",
                        description: "A friction is anything that annoys or frustrates you in daily life - slow WiFi, broken tools, unclear processes, etc."
                    )

                    HelpSection(
                        emoji: "➕",
                        title: "Adding Frictions",
                        description: "Go to the 'Add New' tab to create friction items. Rate their annoyance level (1-5) and choose a category."
                    )

                    HelpSection(
                        emoji: "👆",
                        title: "Recording Encounters",
                        description: "Each time you experience a friction, tap the big \"I just experienced this!\" button. This tracks how often it happens."
                    )

                    HelpSection(
                        emoji: "🔥",
                        title: "Impact Score",
                        description: "Impact = Encounters × Annoyance Level. A level-5 friction encountered 3 times = 15 impact points. This shows what's really affecting you."
                    )

                    HelpSection(
                        emoji: "🎯",
                        title: "Setting Limits",
                        description: "Set a daily impact limit on the dashboard. Get notified when you exceed it to stay aware of your friction levels."
                    )

                    HelpSection(
                        emoji: "📊",
                        title: "Dashboard Insights",
                        description: "View your friction trends over time, see which category causes the most friction, and track your progress."
                    )

                    HelpSection(
                        emoji: "✅",
                        title: "Marking as Fixed",
                        description: "When you solve a friction, edit it and change the status to 'Fixed'. This removes it from active tracking."
                    )
                }
            }

            Button {
                isPresented = false
            } label: {
                Text("Got it!")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(width: 600, height: 700)
    }
}

// MARK: - Help Section

struct HelpSection: View {
    let emoji: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
