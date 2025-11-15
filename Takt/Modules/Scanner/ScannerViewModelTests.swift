//
//  ScannerViewModelTests.swift
//  Takt
//
//  Created by Artem Alekseev on 14.11.25.
//

import Testing
import Foundation
@testable import Takt

@Suite("Scanner ViewModel Tests")
struct ScannerViewModelTests {
    
    // MARK: - Test Setup
    var sut: ScannerViewModel {
        ScannerViewModel()
    }
    
    // MARK: - Tests
    @Test("Initial state is correct")
    func testInitialState() async throws {
        let viewModel = sut
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Performs action successfully")
    func testPerformAction() async throws {
        let viewModel = sut
        
        await viewModel.performAction()
        
        #expect(viewModel.isLoading == false)
    }
}
