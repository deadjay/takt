//
//  EventsListView.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import SwiftUI

struct EventsListView: View {
    @State private var viewModel: EventsListViewModel
    @State private var showingEventDetail = false
    @State private var selectedEvent: Event?

    init(viewModel: EventsListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            if viewModel.events.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                eventsList
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, events: $viewModel.events)
            }
        }
    }

    // MARK: - View Components

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(TaktTheme.textMuted)

            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Import an image or manually add events to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var eventsList: some View {
        List {
            ForEach(viewModel.filteredEvents) { event in
                EventRow(event: event)
                    .onTapGesture {
                        selectedEvent = event
                        showingEventDetail = true
                    }
            }
            .onDelete(perform: deleteEvents)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search events...")
        .onChange(of: viewModel.searchText) { _, newValue in
            Task {
                await viewModel.searchEvents(query: newValue)
            }
        }
    }

    // MARK: - Actions

    private func deleteEvents(offsets: IndexSet) {
        let eventsToDelete = offsets.map { viewModel.filteredEvents[$0] }
        let ids = eventsToDelete.map { $0.id }

        Task {
            await viewModel.deleteEvents(withIds: ids)
        }
    }
}
