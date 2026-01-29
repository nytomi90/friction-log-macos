//
//  ContentView.swift
//  FrictionLog
//
//  Main content view with tab navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FrictionViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            FrictionListView(viewModel: viewModel)
                .tabItem {
                    Label("Friction Items", systemImage: "list.bullet")
                }
                .tag(1)

            AddFrictionView(viewModel: viewModel)
                .tabItem {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
                .tag(2)
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

#Preview {
    ContentView()
}
