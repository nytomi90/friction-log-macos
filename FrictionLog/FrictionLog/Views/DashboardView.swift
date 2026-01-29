//
//  DashboardView.swift
//  FrictionLog
//
//  Dashboard view showing friction analytics
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var viewModel: FrictionViewModel
    @State private var trendDays = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Friction Dashboard")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    Button {
                        Task {
                            await viewModel.loadAllAnalytics(trendDays: trendDays)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal)

                if viewModel.isLoading && viewModel.currentScore == nil {
                    Spacer()
                    ProgressView("Loading analytics...")
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.currentScore == nil {
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
                                await viewModel.loadAllAnalytics(trendDays: trendDays)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    // Current Score Card
                    if let score = viewModel.currentScore {
                        CurrentScoreCard(score: score)
                            .padding(.horizontal)
                    }

                    // Trend Chart
                    if !viewModel.trendData.isEmpty {
                        TrendChartCard(
                            trendData: viewModel.trendData,
                            selectedDays: $trendDays,
                            onDaysChanged: {
                                Task {
                                    await viewModel.loadTrend(days: trendDays)
                                }
                            }
                        )
                        .padding(.horizontal)
                    }

                    // Category Breakdown Chart
                    if let breakdown = viewModel.categoryBreakdown {
                        CategoryBreakdownCard(breakdown: breakdown)
                            .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadAllAnalytics(trendDays: trendDays)
        }
    }
}

// MARK: - Current Score Card

struct CurrentScoreCard: View {
    let score: CurrentScore

    var body: some View {
        VStack(spacing: 12) {
            Text("\(score.currentScore)")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(scoreColor)
            Text("Current Friction Score")
                .font(.title2)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Label("\(score.activeCount) active", systemImage: "circle.fill")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private var scoreColor: Color {
        switch score.currentScore {
        case 0...10: return .green
        case 11...25: return .orange
        default: return .red
        }
    }
}

// MARK: - Trend Chart Card

struct TrendChartCard: View {
    let trendData: [TrendDataPoint]
    @Binding var selectedDays: Int
    let onDaysChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friction Trend")
                    .font(.title2)
                    .bold()
                Spacer()
                Picker("Days", selection: $selectedDays) {
                    Text("7d").tag(7)
                    Text("30d").tag(30)
                    Text("90d").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: selectedDays) { _ in
                    onDaysChanged()
                }
            }

            Chart(trendData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Score", dataPoint.score)
                )
                .foregroundStyle(Color.blue.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Score", dataPoint.score)
                )
                .foregroundStyle(Color.blue.opacity(0.1).gradient)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Category Breakdown Card

struct CategoryBreakdownCard: View {
    let breakdown: CategoryBreakdown

    private var categoryData: [(category: Category, score: Int)] {
        Category.allCases.map { category in
            (category, breakdown.score(for: category))
        }.filter { $0.score > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown by Category")
                .font(.title2)
                .bold()

            if categoryData.isEmpty {
                Text("No active friction items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Chart(categoryData, id: \.category) { item in
                    BarMark(
                        x: .value("Category", item.category.displayName),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(categoryColor(item.category))
                    .annotation(position: .top) {
                        Text("\(item.score)")
                            .font(.caption)
                            .bold()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)

                // Legend
                HStack(spacing: 16) {
                    ForEach(categoryData, id: \.category) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(categoryColor(item.category))
                                .frame(width: 8, height: 8)
                            Text(item.category.displayName)
                                .font(.caption)
                            Text("(\(item.score))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private func categoryColor(_ category: Category) -> Color {
        switch category {
        case .home: return .blue
        case .work: return .purple
        case .digital: return .orange
        case .health: return .green
        case .other: return .gray
        }
    }
}

#Preview {
    DashboardView(viewModel: FrictionViewModel())
}
