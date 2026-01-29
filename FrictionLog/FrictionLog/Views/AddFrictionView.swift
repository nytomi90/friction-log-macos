//
//  AddFrictionView.swift
//  FrictionLog
//
//  Form for adding new friction items
//

import SwiftUI

struct AddFrictionView: View {
    @StateObject private var apiClient = APIClient()
    @State private var title = ""
    @State private var description = ""
    @State private var annoyanceLevel = 3
    @State private var selectedCategory: Category = .home

    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Friction Item")
                .font(.largeTitle)
                .bold()

            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                Section("Annoyance Level") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("1")
                            Slider(value: Binding(
                                get: { Double(annoyanceLevel) },
                                set: { annoyanceLevel = Int($0) }
                            ), in: 1...5, step: 1)
                            Text("5")
                        }
                        Text("Level: \(annoyanceLevel)")
                            .font(.headline)
                            .foregroundColor(annoyanceColor)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Clear") {
                    clearForm()
                }
                .buttonStyle(.bordered)

                Button("Add Friction Item") {
                    Task {
                        await saveFrictionItem()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || isSaving)
            }

            if showSuccess {
                Text("✓ Friction item added successfully!")
                    .foregroundColor(.green)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var annoyanceColor: Color {
        switch annoyanceLevel {
        case 1...2: return .green
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }

    private func saveFrictionItem() async {
        isSaving = true
        error = nil
        showSuccess = false

        let item = FrictionItemCreate(
            title: title,
            description: description.isEmpty ? nil : description,
            annoyanceLevel: annoyanceLevel,
            category: selectedCategory
        )

        do {
            _ = try await apiClient.createFrictionItem(item)
            showSuccess = true
            clearForm()

            // Hide success message after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            showSuccess = false
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }

    private func clearForm() {
        title = ""
        description = ""
        annoyanceLevel = 3
        selectedCategory = .home
    }
}

#Preview {
    AddFrictionView()
}
