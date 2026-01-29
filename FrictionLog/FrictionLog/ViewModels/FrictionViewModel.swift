//
//  FrictionViewModel.swift
//  FrictionLog
//
//  View model for managing friction items and analytics
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class FrictionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [FrictionItemResponse] = []
    @Published var currentScore: CurrentScore?
    @Published var trendData: [TrendDataPoint] = []
    @Published var categoryBreakdown: CategoryBreakdown?
    @Published var mostAnnoyingItems: [MostAnnoyingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let apiClient: APIClient

    // Track which threshold notifications we've sent today
    private var notifiedAt75Percent = false
    private var notifiedAt90Percent = false
    private var notifiedAt100Percent = false
    private var lastNotificationDate = Date()

    // MARK: - Initialization

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Friction Items Operations

    func loadItems(status: Status? = nil, category: Category? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await apiClient.listFrictionItems(status: status, category: category)
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createItem(title: String, description: String?, annoyanceLevel: Int, category: Category, encounterLimit: Int? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let item = FrictionItemCreate(
            title: title,
            description: description?.isEmpty == false ? description : nil,
            annoyanceLevel: annoyanceLevel,
            category: category,
            encounterLimit: encounterLimit
        )

        do {
            let newItem = try await apiClient.createFrictionItem(item)
            items.insert(newItem, at: 0) // Add to beginning of list
            successMessage = "Friction item added successfully!"

            // Refresh score after adding item
            await loadScore()

            isLoading = false

            // Clear success message after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            successMessage = nil

            return true
        } catch {
            errorMessage = "Failed to create item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func updateItem(_ id: Int, title: String? = nil, description: String? = nil, annoyanceLevel: Int? = nil, category: Category? = nil, status: Status? = nil, encounterLimit: Int? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        let update = FrictionItemUpdate(
            title: title,
            description: description,
            annoyanceLevel: annoyanceLevel,
            category: category,
            status: status,
            encounterLimit: encounterLimit
        )

        do {
            let updatedItem = try await apiClient.updateFrictionItem(id, update: update)

            // Update item in local list
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updatedItem
            }

            // Refresh score after updating
            await loadScore()

            isLoading = false

            return true
        } catch {
            errorMessage = "Failed to update item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteItem(_ id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiClient.deleteFrictionItem(id)

            // Remove from local list
            items.removeAll { $0.id == id }

            successMessage = "Item deleted successfully!"

            // Refresh score after deleting
            await loadScore()

            isLoading = false

            try? await Task.sleep(for: .seconds(2))
            successMessage = nil

            return true
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Analytics Operations

    func loadScore() async {
        do {
            currentScore = try await apiClient.getCurrentScore()
        } catch {
            errorMessage = "Failed to load score: \(error.localizedDescription)"
        }
    }

    func loadTrend(days: Int = 30) async {
        do {
            trendData = try await apiClient.getFrictionTrend(days: days)
        } catch {
            errorMessage = "Failed to load trend data: \(error.localizedDescription)"
        }
    }

    func loadCategoryBreakdown() async {
        do {
            categoryBreakdown = try await apiClient.getCategoryBreakdown()
        } catch {
            errorMessage = "Failed to load category breakdown: \(error.localizedDescription)"
        }
    }

    func loadMostAnnoyingItems(limit: Int = 5) async {
        do {
            mostAnnoyingItems = try await apiClient.getMostAnnoyingItems(limit: limit)
        } catch {
            errorMessage = "Failed to load most annoying items: \(error.localizedDescription)"
        }
    }

    func loadAllAnalytics(trendDays: Int = 30) async {
        isLoading = true
        errorMessage = nil

        await loadScore()
        await loadTrend(days: trendDays)
        await loadCategoryBreakdown()
        await loadMostAnnoyingItems()

        isLoading = false
    }

    // MARK: - Helper Methods

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    func checkBackendHealth() async -> Bool {
        do {
            return try await apiClient.healthCheck()
        } catch {
            errorMessage = "Backend is not responding. Please ensure the server is running at http://localhost:8000"
            return false
        }
    }

    @MainActor
    func incrementEncounter(_ id: Int) async -> Bool {
        do {
            let updatedItem = try await apiClient.incrementEncounter(id)

            // Force update the items array to trigger UI refresh
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updatedItem
                // Force SwiftUI to detect the change
                items = items
            }

            // Refresh score and most annoying
            await loadScore()
            await loadMostAnnoyingItems()

            // Check if individual item limit exceeded
            if updatedItem.isLimitExceeded {
                requestNotification(for: updatedItem)
            }

            // Check global daily limit and send threshold notifications
            if let score = currentScore {
                checkGlobalLimitThresholds(score: score)
            }

            return true
        } catch {
            errorMessage = "Failed to increment encounter: \(error.localizedDescription)"
            return false
        }
    }

    func setGlobalDailyLimit(_ limit: Int?) async {
        do {
            _ = try await apiClient.setGlobalDailyLimit(limit)

            // Refresh score to show updated limit
            await loadScore()

            successMessage = limit != nil ? "Daily limit set to \(limit!)" : "Daily limit removed"

            try? await Task.sleep(for: .seconds(2))
            successMessage = nil
        } catch {
            errorMessage = "Failed to set daily limit: \(error.localizedDescription)"
        }
    }

    private func requestNotification(for item: FrictionItemResponse) {
        #if os(macOS)
        let content = UNMutableNotificationContent()
        content.title = "Friction Limit Exceeded"
        content.body = "\"\(item.title)\" has reached its daily limit (\(item.encounterCount)/\(item.encounterLimit ?? 0))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "limit-exceeded-\(item.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        #endif
    }

    private func checkGlobalLimitThresholds(score: CurrentScore) {
        // Reset notification flags if it's a new day
        let calendar = Calendar.current
        if !calendar.isDate(lastNotificationDate, inSameDayAs: Date()) {
            notifiedAt75Percent = false
            notifiedAt90Percent = false
            notifiedAt100Percent = false
            lastNotificationDate = Date()
        }

        // Check if global limit is set
        guard let percentage = score.globalLimitPercentage,
              let limit = score.globalDailyLimit else {
            return
        }

        #if os(macOS)
        let content = UNMutableNotificationContent()
        content.sound = .default

        // Check thresholds and send appropriate notifications
        if percentage >= 100 && !notifiedAt100Percent {
            content.title = "🔴 Daily Limit Exceeded!"
            content.body = "You've exceeded your daily friction limit! Impact: \(score.weightedEncountersToday)/\(limit) points (\(percentage)%)"
            notifiedAt100Percent = true

            let request = UNNotificationRequest(
                identifier: "global-limit-100",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)

        } else if percentage >= 90 && !notifiedAt90Percent {
            content.title = "⚠️ Almost at Daily Limit"
            content.body = "You're at \(percentage)% of your daily friction limit. Impact: \(score.weightedEncountersToday)/\(limit) points"
            notifiedAt90Percent = true

            let request = UNNotificationRequest(
                identifier: "global-limit-90",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)

        } else if percentage >= 75 && !notifiedAt75Percent {
            content.title = "💡 Approaching Daily Limit"
            content.body = "You're at \(percentage)% of your daily friction limit. Impact: \(score.weightedEncountersToday)/\(limit) points"
            notifiedAt75Percent = true

            let request = UNNotificationRequest(
                identifier: "global-limit-75",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
        #endif
    }
}

