//
//  EventsListView.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import SwiftUI

struct EventsListView: View {
    @State private var viewModel: EventsListViewModel
    @State private var selectedEvent: Event?
    @State private var isSearching = false
    @FocusState private var searchFieldFocused: Bool
    @Binding var showCalendar: Bool

    init(viewModel: EventsListViewModel, showCalendar: Binding<Bool>) {
        _viewModel = State(wrappedValue: viewModel)
        _showCalendar = showCalendar
    }

    var body: some View {
        ZStack {
            TaktTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.events.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    // Header
                    eventsHeader

                    // Event rows
                    eventsList
                }

                // Bottom bar: search + calendar button
                bottomBar
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, events: $viewModel.events)
        }
    }

    // MARK: - Header

    private var eventsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TAKT // EVENTS")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(TaktTheme.accent)
                .tracking(2)

            Text("Events")
                .font(.system(size: 42, weight: .black))
                .foregroundColor(TaktTheme.textPrimary)
                .tracking(-1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TaktTheme.contentPadding)
        .padding(.vertical, 20)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(TaktTheme.textMuted)

            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(TaktTheme.textPrimary)

            Text("Scan an image or paste text to extract events")
                .font(.body)
                .foregroundColor(TaktTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Events List

    private var eventsList: some View {
        List {
            ForEach(viewModel.filteredEvents) { event in
                EventRow(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: TaktTheme.contentPadding, bottom: 0, trailing: TaktTheme.contentPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(TaktTheme.cardBorder)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteEvents(withIds: [event.id])
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.bottom, 60)
        .onChange(of: viewModel.searchText) { _, newValue in
            Task {
                await viewModel.searchEvents(query: newValue)
            }
        }
    }

    // MARK: - Bottom Bar (Search + Calendar button)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if isSearching {
                // Expanded search field
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(TaktTheme.accent)
                            .font(.system(size: 16))

                        TextField("Search extracted events...", text: $viewModel.searchText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .focused($searchFieldFocused)

                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 15, y: 5)

                    Button("Cancel") {
                        viewModel.searchText = ""
                        searchFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching = false
                        }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(TaktTheme.accent)
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.vertical, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Collapsed: search bar + calendar button
                HStack(spacing: 12) {
                    // Search button (expands)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            searchFieldFocused = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(TaktTheme.accent)
                            Text("Search extracted events...")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 15, y: 5)
                    }

                    // Calendar toggle button
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(TaktTheme.textPrimary)
                            .frame(width: 52, height: 52)
                            .background(TaktTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(TaktTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.vertical, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            LinearGradient(
                colors: [TaktTheme.appBackground.opacity(0), TaktTheme.appBackground],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
        )
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
