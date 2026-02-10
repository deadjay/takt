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
                    CalendarView(events: $viewModel.events, showCalendar: $showCalendarInEventsTab)
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
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

#Preview {
    ContentView(viewModel: DIContainer.shared.makeContentViewModel())
}
