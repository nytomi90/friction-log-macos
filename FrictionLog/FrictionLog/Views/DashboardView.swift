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
    @State private var showEditLimit = false
    @State private var editingLimit = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            Text("📊")
                                .font(.largeTitle)
                            Text("Dashboard")
                                .font(.largeTitle)
                                .bold()
                        }
                        Spacer()
                        Button {
                            Task {
                                await viewModel.loadAllAnalytics(trendDays: trendDays)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLoading)
                    }

                    Text("Track your daily friction impact and progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    // Global Daily Limit Section
                    if let score = viewModel.currentScore {
                        GlobalDailyLimitCard(
                            score: score,
                            onEditLimit: {
                                editingLimit = String(score.globalDailyLimit ?? 20)
                                showEditLimit = true
                            }
                        )
                        .padding(.horizontal)
                    }

                    // Most Annoying Items
                    if !viewModel.mostAnnoyingItems.isEmpty {
                        MostAnnoyingItemsCard(items: viewModel.mostAnnoyingItems)
                            .padding(.horizontal)
                    }

                    // Current Score Card
                    if let score = viewModel.currentScore {
                        CurrentScoreCard(score: score)
                            .padding(.horizontal)

                        // Warning section for exceeded limits
                        if score.itemsOverLimit > 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(score.itemsOverLimit) item\(score.itemsOverLimit == 1 ? "" : "s") exceeded their encounter limit")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    Text("Impact: \(score.weightedEncountersToday) points from \(score.totalEncountersToday) encounters")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
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
        .sheet(isPresented: $showEditLimit) {
            EditGlobalLimitSheet(
                limit: $editingLimit,
                onSave: {
                    if let limitValue = Int(editingLimit), limitValue > 0 {
                        Task {
                            await viewModel.setGlobalDailyLimit(limitValue)
                            showEditLimit = false
                        }
                    }
                },
                onCancel: {
                    showEditLimit = false
                }
            )
        }
    }
}

// MARK: - Global Daily Limit Card

struct GlobalDailyLimitCard: View {
    let score: CurrentScore
    let onEditLimit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(score.statusEmoji)
                    .font(.system(size: 48))
                Spacer()
                Button(action: onEditLimit) {
                    Image(systemName: "pencil.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Text("\(score.weightedEncountersToday)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(limitColor)
                Text("/")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("\(score.globalDailyLimit ?? 0)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 2) {
                Text("Daily Friction Impact Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("(\(score.totalEncountersToday) encounters × annoyance levels)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let percentage = score.globalLimitPercentage {
                Text(statusText(percentage: percentage))
                    .font(.headline)
                    .foregroundColor(limitColor)
            } else {
                Text("No daily limit set")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Total Friction Impact Today")
                .font(.caption)
                .foregroundColor(.secondary)
                .bold()

            // Help text
            if score.globalDailyLimit == nil {
                Text("💡 Tip: Set a limit above to track daily friction")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            } else if let percentage = score.globalLimitPercentage, percentage > 0 {
                Text("Example: 3 encounters × level 5 = 15 points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(limitBackgroundColor)
        .cornerRadius(12)
    }

    private var limitColor: Color {
        guard let percentage = score.globalLimitPercentage else {
            return .primary
        }

        if percentage < 50 {
            return .green
        } else if percentage < 75 {
            return .orange
        } else if percentage < 100 {
            return .red
        } else {
            return .red
        }
    }

    private var limitBackgroundColor: Color {
        guard let percentage = score.globalLimitPercentage else {
            return Color.gray.opacity(0.08)
        }

        if percentage >= 100 {
            return Color.red.opacity(0.1)
        } else if percentage >= 75 {
            return Color.orange.opacity(0.1)
        } else {
            return Color.green.opacity(0.08)
        }
    }

    private func statusText(percentage: Int) -> String {
        if percentage < 50 {
            return "Great! Low friction impact (\(percentage)%)"
        } else if percentage < 75 {
            return "Moderate friction today (\(percentage)%)"
        } else if percentage < 100 {
            return "High friction - almost at limit! (\(percentage)%)"
        } else {
            return "⚠️ Daily impact limit exceeded! (\(percentage)%)"
        }
    }
}

// MARK: - Edit Global Limit Sheet

struct EditGlobalLimitSheet: View {
    @Binding var limit: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🎯 Set Daily Impact Limit")
                .font(.title2)
                .bold()

            VStack(spacing: 8) {
                Text("Set a maximum friction impact score per day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("Impact = Encounters × Annoyance Level")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }

            VStack(spacing: 4) {
                Text("Daily Impact Limit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("e.g., 50", text: $limit)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onSubmit {
                        onSave()
                    }
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)

                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(limit.isEmpty || Int(limit) == nil || Int(limit)! < 1)
            }
        }
        .padding(32)
        .frame(width: 400)
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

// MARK: - Most Annoying Items Card

struct MostAnnoyingItemsCard: View {
    let items: [MostAnnoyingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 Most Annoying Today")
                    .font(.title2)
                    .bold()
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        // Rank indicator
                        Text("\(items.firstIndex(where: { $0.id == item.id })! + 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        // Item details
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.headline)
                                .lineLimit(1)
                            HStack(spacing: 8) {
                                // Annoyance level stars
                                HStack(spacing: 2) {
                                    ForEach(0..<item.annoyanceLevel, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("\(item.encounterCount) encounters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Impact score
                        VStack(spacing: 2) {
                            Text("\(item.impact)")
                                .font(.title3)
                                .bold()
                                .foregroundColor(impactColor(item.impact))
                            Text("impact")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private func impactColor(_ impact: Int) -> Color {
        if impact >= 20 {
            return .red
        } else if impact >= 10 {
            return .orange
        } else {
            return .primary
        }
    }
}

#Preview {
    DashboardView(viewModel: FrictionViewModel())
}
