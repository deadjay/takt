//
//  ScannerViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 14.11.25.
//

import Foundation
import Observation

@Observable
final class ScannerViewModel {
    
    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    // private let someUseCase: SomeUseCaseProtocol
    
    // MARK: - Init
    init(
        // someUseCase: SomeUseCaseProtocol
    ) {
        // self.someUseCase = someUseCase
    }
    
    // MARK: - Actions
    @MainActor
    func performAction() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // TODO: Implement action
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
