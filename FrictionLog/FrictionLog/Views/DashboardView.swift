//
//  DashboardView.swift
//  FrictionLog
//
//  Dashboard view showing friction analytics
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: FrictionViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Friction Dashboard")
                .font(.largeTitle)
                .bold()

            if viewModel.isLoading && viewModel.currentScore == nil {
                ProgressView("Loading...")
            } else if let error = viewModel.errorMessage {
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
                            await viewModel.loadScore()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let score = viewModel.currentScore {
                VStack(spacing: 10) {
                    Text("\(score.currentScore)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(scoreColor(score.currentScore))
                    Text("Current Friction Score")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("\(score.activeCount) Active Items")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)

                    Button("Refresh") {
                        Task {
                            await viewModel.loadScore()
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack {
                    Text("No data available")
                        .foregroundColor(.secondary)
                    Button("Load Data") {
                        Task {
                            await viewModel.loadScore()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadScore()
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0...10: return .green
        case 11...25: return .orange
        default: return .red
        }
    }
}

#Preview {
    DashboardView(viewModel: FrictionViewModel())
}
