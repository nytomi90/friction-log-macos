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
            // Header
            HStack {
                Text("Friction Items")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button {
                    Task {
                        await loadWithFilters()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }
            .padding()

            // Filters
            VStack(alignment: .leading, spacing: 12) {
                // Status filter
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter by Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Status", selection: $selectedStatus) {
                        Text("All").tag(nil as Status?)
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as Status?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedStatus) { _ in
                        Task {
                            await loadWithFilters()
                        }
                    }
                }

                // Category filter
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter by Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(nil as Category?)
                        ForEach(Category.allCases) { category in
                            Text(category.displayName).tag(category as Category?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCategory) { _ in
                        Task {
                            await loadWithFilters()
                        }
                    }
                }

                // Results count
                if !viewModel.items.isEmpty {
                    Text("\(viewModel.items.count) item\(viewModel.items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            Divider()

            // Content
            if viewModel.isLoading && viewModel.items.isEmpty {
                Spacer()
                ProgressView("Loading items...")
                Spacer()
            } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            await loadWithFilters()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if viewModel.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text(filtersActive ? "No items match filters" : "No friction items yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    if filtersActive {
                        Button("Clear Filters") {
                            selectedStatus = nil
                            selectedCategory = nil
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("Add your first item to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        FrictionItemRow(
                            item: item,
                            viewModel: viewModel,
                            onEdit: {
                                itemToEdit = item
                                showingEditSheet = true
                            }
                        )
                    }
                }
                .refreshable {
                    await loadWithFilters()
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

struct FrictionItemRow: View {
    let item: FrictionItemResponse
    @ObservedObject var viewModel: FrictionViewModel
    let onEdit: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= item.annoyanceLevel ? "star.fill" : "star")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            .padding(item.isLimitExceeded ? 8 : 0)
            .background(item.isLimitExceeded ? Color.red.opacity(0.1) : Color.clear)
            .cornerRadius(item.isLimitExceeded ? 6 : 0)

            HStack {
                Text(item.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)

                Text(item.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)

                Spacer()

                // Encounter button
                if item.status != .fixed {
                    Button {
                        Task {
                            _ = await viewModel.incrementEncounter(item.id)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                            if let limit = item.encounterLimit {
                                Text("\(item.encounterCount)/\(limit)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(item.isLimitExceeded ? .red : .primary)
                            } else {
                                Text("\(item.encounterCount)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(item.isLimitExceeded ? .red : .blue)
                }

                // Edit button
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                // Delete button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deleteItem(item.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(item.title)'?")
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .notFixed: return .red
        case .inProgress: return .orange
        case .fixed: return .green
        }
    }
}

#Preview {
    FrictionListView(viewModel: FrictionViewModel())
}
