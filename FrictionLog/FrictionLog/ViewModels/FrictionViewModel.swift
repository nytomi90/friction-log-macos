//
//  FrictionViewModel.swift
//  FrictionLog
//
//  View model for managing friction items and analytics
//

import Foundation
import SwiftUI

@MainActor
class FrictionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [FrictionItemResponse] = []
    @Published var currentScore: CurrentScore?
    @Published var trendData: [TrendDataPoint] = []
    @Published var categoryBreakdown: CategoryBreakdown?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let apiClient: APIClient

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

    func createItem(title: String, description: String?, annoyanceLevel: Int, category: Category) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let item = FrictionItemCreate(
            title: title,
            description: description?.isEmpty == false ? description : nil,
            annoyanceLevel: annoyanceLevel,
            category: category
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

    func updateItem(_ id: Int, title: String? = nil, description: String? = nil, annoyanceLevel: Int? = nil, category: Category? = nil, status: Status? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        let update = FrictionItemUpdate(
            title: title,
            description: description,
            annoyanceLevel: annoyanceLevel,
            category: category,
            status: status
        )

        do {
            let updatedItem = try await apiClient.updateFrictionItem(id, update: update)

            // Update item in local list
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updatedItem
            }

            successMessage = "Item updated successfully!"

            // Refresh score after updating
            await loadScore()

            isLoading = false

            try? await Task.sleep(for: .seconds(2))
            successMessage = nil

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

    func loadAllAnalytics(trendDays: Int = 30) async {
        isLoading = true
        errorMessage = nil

        await loadScore()
        await loadTrend(days: trendDays)
        await loadCategoryBreakdown()

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
}
