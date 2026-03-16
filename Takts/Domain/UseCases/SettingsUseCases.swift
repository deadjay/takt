//
//  SettingsUseCases.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import Foundation

// MARK: - Protocols

protocol GetSettingsUseCaseProtocol {
    func execute() -> AppSettings
}

protocol SaveSettingsUseCaseProtocol {
    func execute(_ settings: AppSettings)
}

// MARK: - Implementations

final class GetSettingsUseCase_Settings: GetSettingsUseCaseProtocol {
    private let repository: SettingsRepositoryProtocol

    init(repository: SettingsRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AppSettings {
        repository.getSettings()
    }
}

final class SaveSettingsUseCase: SaveSettingsUseCaseProtocol {
    private let repository: SettingsRepositoryProtocol

    init(repository: SettingsRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ settings: AppSettings) {
        repository.saveSettings(settings)
    }
}
