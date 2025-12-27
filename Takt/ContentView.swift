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

            // Events Tab (List/Calendar Toggle)
            NavigationView {
                Group {
                    if showCalendarInEventsTab {
                        CalendarView(events: $viewModel.events)
                    } else {
                        EventsListView(viewModel: DIContainer.shared.makeEventsListViewModel())
                    }
                }
                .navigationTitle("Events")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCalendarInEventsTab.toggle()
                        } label: {
                            Image(systemName: showCalendarInEventsTab ? "list.bullet" : "calendar")
                        }
                    }
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
