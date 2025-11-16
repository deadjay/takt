//
//  TextInputPickerView.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import SwiftUI
import UIKit

struct TextInputPickerView: View {
    @Binding var inputText: String
    @State private var showingTextInputSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            if !inputText.isEmpty {
                // Show preview of pasted text
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Pasted Text Preview")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            inputText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView {
                        Text(inputText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Paste Text with Dates")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Paste or type text containing dates, deadlines, and event information")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                showingTextInputSheet = true
            }) {
                HStack {
                    Image(systemName: inputText.isEmpty ? "text.badge.plus" : "arrow.clockwise")
                    Text(inputText.isEmpty ? "Enter Text" : "Edit Text")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding()
        .sheet(isPresented: $showingTextInputSheet) {
            TextInputSheet(inputText: $inputText)
        }
    }
}

// MARK: - Text Input Sheet
struct TextInputSheet: View {
    @Binding var inputText: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Paste or type text containing dates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                TextEditor(text: $inputText)
                    .frame(maxHeight: .infinity)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("Example:\nReturn package by 25.12.2024\nPay invoice until 01.01.2025")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                
                HStack(spacing: 12) {
                    Button(action: pasteFromClipboard) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        inputText = ""
                    }) {
                        Label("Clear", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
            }
            .padding()
            .navigationTitle("Enter Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(inputText.isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            inputText = clipboardText
        }
    }
}

#Preview {
    TextInputPickerView(inputText: .constant(""))
}
