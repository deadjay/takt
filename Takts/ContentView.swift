//
//  ContentView.swift
//  Takt
//
//  Created by Artem Alekseev on 11.06.25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Bindable var viewModel: ContentViewModel
    @State private var showCalendarInEventsTab: Bool = false
    @State private var settingsViewModel = DIContainer.shared.makeSettingsViewModel()

    var body: some View {
        TabView {
            // Scan Tab (Image/Text Processing)
            ScanView(viewModel: DIContainer.shared.makeScanViewModel())
                .tabItem {
                    Image(systemName: "doc.text.viewfinder")
                    Text("Scan")
                }

            // Events Tab — ZStack keeps tab identity stable
            ZStack {
                if showCalendarInEventsTab {
                    CalendarView(
                        events: $viewModel.events,
                        showCalendar: $showCalendarInEventsTab,
                        onSave: { event in Task { await viewModel.update(event: event) } },
                        onDelete: { id in
                            Task {
                                if let idx = viewModel.events.firstIndex(where: { $0.id == id }) {
                                    await viewModel.delete(at: IndexSet(integer: idx))
                                }
                            }
                        },
                        onAppearReload: { await viewModel.loadEvents() }
                    )
                } else {
                    EventsListView(
                        viewModel: DIContainer.shared.makeEventsListViewModel(),
                        showCalendar: $showCalendarInEventsTab
                    )
                }
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Events")
            }

            // Settings Tab
            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .preferredColorScheme(colorScheme)
        .task {
            await viewModel.onAppear()
        }
    }

    private var colorScheme: ColorScheme? {
        switch settingsViewModel.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    ContentView(viewModel: DIContainer.shared.makeContentViewModel())
}
