//
//  FrictionListView.swift
//  FrictionLog
//
//  List view for managing friction items
//

import SwiftUI

struct FrictionListView: View {
    @ObservedObject var viewModel: FrictionViewModel
    @State private var selectedStatus: Status?
    @State private var selectedCategory: Category?
    @State private var showingEditSheet = false
    @State private var itemToEdit: FrictionItemResponse?

    var body: some View {
        VStack(spacing: 0) {
            // Modern Header with gradient
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Text("📋")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Friction Items")
                                .font(.title).bold()
                            if !viewModel.items.isEmpty {
                                Text("\(viewModel.items.count) item\(viewModel.items.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        Task {
                            await loadWithFilters()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }

                // Modern Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Status filters
                        FilterPill(
                            title: "All",
                            emoji: "📊",
                            isSelected: selectedStatus == nil && selectedCategory == nil
                        ) {
                            selectedStatus = nil
                            selectedCategory = nil
                        }

                        ForEach(Status.allCases, id: \.self) { status in
                            FilterPill(
                                title: status.displayName,
                                emoji: status.emoji,
                                isSelected: selectedStatus == status,
                                color: status.color
                            ) {
                                selectedStatus = selectedStatus == status ? nil : status
                            }
                        }

                        Divider()
                            .frame(height: 24)

                        // Category filters
                        ForEach(Category.allCases) { category in
                            FilterPill(
                                title: category.displayName,
                                emoji: category.emoji,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: selectedStatus) { _ in
                    Task { await loadWithFilters() }
                }
                .onChange(of: selectedCategory) { _ in
                    Task { await loadWithFilters() }
                }
            }
            .padding(.vertical, 20)
            .background(Color.gray.opacity(0.05))

            Divider()

            // Content
            if viewModel.isLoading && viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading your frictions...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
                Spacer()
                ErrorStateView(error: error) {
                    Task { await loadWithFilters() }
                }
                Spacer()
            } else if viewModel.items.isEmpty {
                Spacer()
                EmptyStateView(filtersActive: filtersActive) {
                    selectedStatus = nil
                    selectedCategory = nil
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.items) { item in
                            ModernFrictionCard(
                                item: item,
                                viewModel: viewModel,
                                onEdit: {
                                    itemToEdit = item
                                    showingEditSheet = true
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadWithFilters()
        }
        .sheet(item: $itemToEdit) { item in
            EditFrictionView(item: item, viewModel: viewModel, isPresented: $showingEditSheet)
        }
    }

    private var filtersActive: Bool {
        selectedStatus != nil || selectedCategory != nil
    }

    private func loadWithFilters() async {
        await viewModel.loadItems(status: selectedStatus, category: selectedCategory)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.body)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? color.opacity(0.15)
                    : Color.gray.opacity(0.08)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Friction Card

struct ModernFrictionCard: View {
    let item: FrictionItemResponse
    @ObservedObject var viewModel: FrictionViewModel
    let onEdit: () -> Void
    @State private var showingDeleteConfirmation = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(item.category.gradient)
                    .frame(width: 56, height: 56)

                Text(item.category.emoji)
                    .font(.system(size: 28))
            }
            .shadow(color: item.category.color.opacity(0.3), radius: 8, x: 0, y: 4)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Text(item.status.emoji)
                        Text(item.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(item.status.color.opacity(0.15))
                    .foregroundColor(item.status.color)
                    .cornerRadius(12)
                }

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    // Annoyance level
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= item.annoyanceLevel ? "flame.fill" : "flame")
                                .foregroundColor(level <= item.annoyanceLevel ? .orange : .gray.opacity(0.3))
                                .font(.caption)
                        }
                    }

                    Spacer()

                    // Encounter button
                    if item.status != .fixed {
                        Button {
                            Task {
                                _ = await viewModel.incrementEncounter(item.id)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.caption)
                                if let limit = item.encounterLimit {
                                    Text("\(item.encounterCount)/\(limit)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                } else {
                                    Text("\(item.encounterCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(item.isLimitExceeded ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundColor(item.isLimitExceeded ? .red : .blue)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    // Actions
                    HStack(spacing: 8) {
                        Button {
                            onEdit()
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 12 : 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isLimitExceeded ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deleteItem(item.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(item.title)'? This action cannot be undone.")
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let filtersActive: Bool
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Text(filtersActive ? "🔍" : "🎉")
                    .font(.system(size: 64))
            }

            VStack(spacing: 8) {
                Text(filtersActive ? "No Results Found" : "All Clear!")
                    .font(.title2)
                    .bold()

                Text(filtersActive ? "Try adjusting your filters" : "No friction items yet. Add your first one to start tracking!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if filtersActive {
                Button {
                    onClearFilters()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear Filters")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
}

// MARK: - Error State

struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.title2)
                    .bold()

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                onRetry()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

#Preview {
    FrictionListView(viewModel: FrictionViewModel())
}
