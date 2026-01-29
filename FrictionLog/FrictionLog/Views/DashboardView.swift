//
//  DashboardView.swift
//  FrictionLog
//
//  Dashboard view showing friction analytics
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var apiClient = APIClient()
    @State private var currentScore: CurrentScore?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Friction Dashboard")
                .font(.largeTitle)
                .bold()

            if isLoading {
                ProgressView("Loading...")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadData()
                        }
                    }
                }
            } else if let score = currentScore {
                VStack(spacing: 10) {
                    Text("\(score.currentScore)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Current Friction Score")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("\(score.activeCount) Active Items")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            currentScore = try await apiClient.getCurrentScore()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    DashboardView()
}
