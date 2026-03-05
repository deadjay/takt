//
//  SettingsViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import Foundation
import Observation

@Observable
final class SettingsViewModel {

    // MARK: - State
    var appearanceMode: AppSettings.AppearanceMode = .system

    // MARK: - Dependencies
    private let getSettingsUseCase: GetSettingsUseCaseProtocol
    private let saveSettingsUseCase: SaveSettingsUseCaseProtocol

    // MARK: - Init
    init(
        getSettingsUseCase: GetSettingsUseCaseProtocol,
        saveSettingsUseCase: SaveSettingsUseCaseProtocol
    ) {
        self.getSettingsUseCase = getSettingsUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        loadSettings()
    }

    // MARK: - Actions

    func loadSettings() {
        let settings = getSettingsUseCase.execute()
        appearanceMode = settings.appearanceMode
    }

    func setAppearanceMode(_ mode: AppSettings.AppearanceMode) {
        appearanceMode = mode
        var settings = AppSettings()
        settings.appearanceMode = mode
        saveSettingsUseCase.execute(settings)
    }
}
