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
    @State private var scrollProxy: ScrollViewProxy?
    @State private var didScrollToToday = false
    @FocusState private var searchFieldFocused: Bool
    @Binding var showCalendar: Bool

    init(viewModel: EventsListViewModel, showCalendar: Binding<Bool>) {
        _viewModel = State(wrappedValue: viewModel)
        _showCalendar = showCalendar
    }

    var body: some View {
        ZStack {
            TaktsTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.events.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    // Event rows with header overlay + floating buttons
                    eventsList
                        .safeAreaInset(edge: .top, spacing: 0) {
                            eventsHeader
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if !isSearching {
                                floatingButtons
                            }
                        }
                }

                // Expanded search bar (below list)
                if isSearching {
                    expandedSearchBar
                }
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                events: $viewModel.events,
                onSave: { updated in
                    Task { await viewModel.updateEvent(updated) }
                },
                onDelete: { id in
                    Task { await viewModel.deleteEvents(withIds: [id]) }
                }
            )
        }
    }

    // MARK: - Header

    private var eventsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TAKT // EVENTS")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(TaktsTheme.accent)
                .tracking(2)

            Text("Events")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(TaktsTheme.textPrimary)
                .tracking(-1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TaktsTheme.contentPadding)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(TaktsTheme.textMuted)

            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(TaktsTheme.textPrimary)

            Text("Scan an image or paste text to extract events")
                .font(.body)
                .foregroundColor(TaktsTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Events List

    private var eventsList: some View {
        ScrollViewReader { proxy in
            List {
                // Past day groups
                ForEach(viewModel.pastDayGroups) { group in
                    ForEach(group.events) { event in
                        eventRow(for: event)
                    }
                }

                // Previous Events label (only if there are past events)
                if !viewModel.pastDayGroups.isEmpty {
                    sectionLabel("PREVIOUS EVENTS \u{2191}")
                }

                // Today divider (always present)
                todayDivider
                    .id("today")
                    .onAppear {
                        if !didScrollToToday {
                            didScrollToToday = true
                            scrollToToday(proxy: proxy)
                        }
                    }

                // All of today's events
                ForEach(viewModel.todayEvents) { event in
                    eventRow(for: event)
                }

                // Upcoming Events label (only if there are future events)
                if !viewModel.upcomingDayGroups.isEmpty {
                    sectionLabel("UPCOMING EVENTS \u{2193}")
                }

                // Tomorrow onward
                ForEach(viewModel.upcomingDayGroups) { group in
                    ForEach(group.events) { event in
                        eventRow(for: event)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 80)
            .onAppear { scrollProxy = proxy }
            .onChange(of: viewModel.searchText) { _, newValue in
                Task {
                    await viewModel.searchEvents(query: newValue)
                }
            }
        }
    }

    @ViewBuilder
    private func eventRow(for event: Event) -> some View {
        EventRow(event: event)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedEvent = event
            }
            .listRowInsets(EdgeInsets(top: 0, leading: TaktsTheme.contentPadding, bottom: 0, trailing: TaktsTheme.contentPadding))
            .listRowBackground(Calendar.current.isDateInToday(event.date) ? TaktsTheme.accent.opacity(0.08) : Color.clear)
            .listRowSeparatorTint(TaktsTheme.cardBorder)
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

    private var todayDivider: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(TaktsTheme.accent)
                .frame(width: 8, height: 8)

            Text(viewModel.todayLabel)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(TaktsTheme.accent)
                .tracking(1.5)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, TaktsTheme.contentPadding)
        .listRowInsets(EdgeInsets())
        .listRowBackground(TaktsTheme.accent.opacity(0.08))
        .listRowSeparator(.hidden)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(TaktsTheme.textMuted)
            .tracking(1.5)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(top: 0, leading: TaktsTheme.contentPadding, bottom: 0, trailing: TaktsTheme.contentPadding))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.35)) {
                proxy.scrollTo("today", anchor: .top)
            }
        }
    }

    // MARK: - Bottom Bar

    // MARK: - Floating Buttons

    private var floatingButtons: some View {
        HStack(spacing: 12) {
            // Search
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearching = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    searchFieldFocused = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(TaktsTheme.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }

            // Today
            Button {
                if let proxy = scrollProxy {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("today", anchor: .top)
                    }
                }
            } label: {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(TaktsTheme.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }

            // Calendar
            Button {
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(TaktsTheme.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
        }
        .padding(.trailing, TaktsTheme.contentPadding)
        .padding(.bottom, 16)
    }

    // MARK: - Expanded Search Bar

    private var expandedSearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(TaktsTheme.accent)
                    .font(.system(size: 16))

                TextField("Search events...", text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .foregroundColor(TaktsTheme.textPrimary)
                    .focused($searchFieldFocused)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(TaktsTheme.textMuted)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(TaktsTheme.cardBackground)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            Button("Cancel") {
                viewModel.searchText = ""
                searchFieldFocused = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearching = false
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(TaktsTheme.accent)
        }
        .padding(.horizontal, TaktsTheme.contentPadding)
        .padding(.vertical, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
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

