//
//  TextInputViewModelTests.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import Testing
import Foundation
@testable import Takt

@Suite("TextInput ViewModel Tests")
struct TextInputViewModelTests {
    
    // MARK: - Test Setup
    var sut: TextInputViewModel {
        TextInputViewModel()
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
