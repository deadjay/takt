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
    
    var body: some View {
        TabView {
            // Image/Text Processing Tab
            VStack(spacing: 20) {
                ImagePickerView(selectedImageData: $viewModel.selectedImageData)
                TextInputPickerView(inputText: $viewModel.inputText)
                
                if viewModel.selectedImageData != nil {
                    Button(action: {
                        Task {
                            await viewModel.processSelectedImage()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "text.viewfinder")
                            }
                            Text(viewModel.isLoading ? "Processing..." : "Extract Event Details")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoading ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    
                    if !viewModel.inputText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Text:")
                                .font(.headline)
                            
                            ScrollView {
                                Text(viewModel.inputText)
                                    .font(.body)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 150)
                        }
                    }
                    
                    if let extractedEvent = viewModel.extractedEvents.first {
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
                    
                    if let errorMessage = viewModel.errorMessage {
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
        CalendarView(events: $viewModel.events)
            .tabItem {
                Image(systemName: "calendar")
                Text("Calendar")
            }
        
        // Events List Tab
        NavigationView {
            EventsListView(viewModel: DIContainer.shared.makeEventsListViewModel())
                .navigationTitle("All Events")
                .navigationBarItems(trailing: Button("Add") {
                    viewModel.isShowingAddEventSheet = true
                })
        }
        .tabItem {
            Image(systemName: "list.bullet")
            Text("Events")
        }
    }
    
    private func addExtractedEvent(_ event: Event) {
        Task {
            await viewModel.confirmAdd(event: event)
        }
    }
}

#Preview {
    ContentView(viewModel: DIContainer.shared.makeContentViewModel())
}
