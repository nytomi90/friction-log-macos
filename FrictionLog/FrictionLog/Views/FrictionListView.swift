//
//  FrictionListView.swift
//  FrictionLog
//
//  List view for managing friction items
//

import SwiftUI

struct FrictionListView: View {
    @ObservedObject var viewModel: FrictionViewModel

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
                        await viewModel.loadItems()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
            }
            .padding()

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
                            await viewModel.loadItems()
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
                    Text("No friction items yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Add your first item to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        FrictionItemRow(item: item, viewModel: viewModel)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadItems()
        }
    }
}

struct FrictionItemRow: View {
    let item: FrictionItemResponse
    @ObservedObject var viewModel: FrictionViewModel
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

                // Quick status change buttons
                Menu {
                    ForEach(Status.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            Task {
                                _ = await viewModel.updateItem(item.id, status: status)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .menuStyle(.borderlessButton)

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
