//
//  ScannerView.swift
//  Takt
//
//  Created by Artem Alekseev on 14.11.25.
//

import SwiftUI

struct ScannerView: View {
    @State private var viewModel: ScannerViewModel
    
    init(viewModel: ScannerViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // TODO: Implement UI
                Text("Scanner View")
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
#Preview {
    ScannerView(
        viewModel: ScannerViewModel()
    )
}
