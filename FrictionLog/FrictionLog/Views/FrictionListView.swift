//
//  FrictionListView.swift
//  FrictionLog
//
//  List view for managing friction items
//

import SwiftUI

struct FrictionListView: View {
    @StateObject private var apiClient = APIClient()
    @State private var items: [FrictionItemResponse] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack {
            Text("Friction Items")
                .font(.largeTitle)
                .bold()
                .padding()

            if isLoading {
                ProgressView("Loading items...")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadItems()
                        }
                    }
                }
            } else if items.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No friction items yet")
                        .foregroundColor(.secondary)
                    Text("Add your first item to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List(items) { item in
                    FrictionItemRow(item: item)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadItems()
        }
    }

    private func loadItems() async {
        isLoading = true
        error = nil

        do {
            items = try await apiClient.listFrictionItems()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct FrictionItemRow: View {
    let item: FrictionItemResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                Text("\(item.annoyanceLevel)/5")
                    .font(.subheadline)
                    .foregroundColor(.orange)
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
            }

            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
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
    FrictionListView()
}
