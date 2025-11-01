//
//  ContentView.swift
//  Takt
//
//  Created by Artem Alekseev on 11.06.25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var textRecognitionService = TextRecognitionService()
    @StateObject private var eventStorage = EventStorageService()
    @State private var selectedImage: UIImage?
    @State private var showingAddEventSheet = false
    
    var body: some View {
        TabView {
            // Image Processing Tab
            NavigationView {
                VStack(spacing: 20) {
                    ImagePickerView(selectedImage: $selectedImage)
                    
                    if let image = selectedImage {
                        Button(action: {
                            Task {
                                await textRecognitionService.recognizeText(from: image)
                            }
                        }) {
                            HStack {
                                if textRecognitionService.isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "text.viewfinder")
                                }
                                Text(textRecognitionService.isProcessing ? "Processing..." : "Extract Event Details")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(textRecognitionService.isProcessing ? Color.gray : Color.green)
                            .cornerRadius(12)
                        }
                        .disabled(textRecognitionService.isProcessing)
                        
                        if !textRecognitionService.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Extracted Text:")
                                    .font(.headline)
                                
                                ScrollView {
                                    Text(textRecognitionService.extractedText)
                                        .font(.body)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .frame(maxHeight: 150)
                            }
                        }
                        
                        if let extractedEvent = textRecognitionService.extractedEvent {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Extracted Event:")
                                    .font(.headline)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name: \(extractedEvent.name)")
                                        .font(.body)
                                    Text("Date: \(extractedEvent.formattedDate)")
                                        .font(.body)
                                    if let deadline = extractedEvent.formattedDeadline {
                                        Text("Deadline: \(deadline)")
                                            .font(.body)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    addExtractedEvent(extractedEvent)
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add to Calendar")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        if let errorMessage = textRecognitionService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Image to Event")
            }
            .tabItem {
                Image(systemName: "photo.on.rectangle.angled")
                Text("Import")
            }
            
            // Calendar Tab
            CalendarView(events: $eventStorage.events)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            // Events List Tab
            NavigationView {
                EventsListView(events: $eventStorage.events)
                    .navigationTitle("All Events")
                    .navigationBarItems(trailing: Button("Add") {
                        showingAddEventSheet = true
                    })
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Events")
            }
        }
        .sheet(isPresented: $showingAddEventSheet) {
            AddEventView(events: $eventStorage.events)
        }
    }
    
    private func addExtractedEvent(_ event: Event) {
        eventStorage.addEvent(event)
        // Clear the extracted event after adding
        textRecognitionService.extractedEvent = nil
        // Show success feedback
        // You could add a toast or alert here
    }
}

struct EventsListView: View {
    @Binding var events: [Event]
    @State private var searchText = ""
    @State private var showingEventDetail = false
    @State private var selectedEvent: Event?
    
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return events.sorted { $0.date < $1.date }
        } else {
            return events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                (event.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.date < $1.date }
        }
    }
    
    var body: some View {
        VStack {
            if events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
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
            } else {
                List {
                    ForEach(filteredEvents) { event in
                        EventRow(event: event)
                            .onTapGesture {
                                selectedEvent = event
                                showingEventDetail = true
                            }
                    }
                    .onDelete(perform: deleteEvents)
                }
                .searchable(text: $searchText, prompt: "Search events...")
            }
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, events: $events)
            }
        }
    }
    
    private func deleteEvents(offsets: IndexSet) {
        let eventsToDelete = offsets.map { filteredEvents[$0] }
        events.removeAll { event in
            eventsToDelete.contains { $0.id == event.id }
        }
    }
}

#Preview {
    ContentView()
}
