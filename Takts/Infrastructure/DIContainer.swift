//
//  DIContainer.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

@MainActor
final class DIContainer {
    static let shared = DIContainer()

    // MARK: - Repositories
    private lazy var eventRepository: EventRepositoryProtocol = {
        UserDefaultsEventRepository()
    }()

    private lazy var settingsRepository: SettingsRepositoryProtocol = {
        UserDefaultsSettingsRepository()
    }()
    
    // MARK: - Services

    lazy var textRecognitionService: TextRecognitionServiceProtocol = {
        DefaultTextRecognitionService()
    }()

    lazy var textEventParserService: TextEventParserServiceProtocol = {
        TextEventParser()
    }()

    lazy var notificationService: NotificationServiceProtocol = {
        NotificationService()
    }()

    // MARK: - Use Cases
    lazy var getEventsUseCase: GetEventsUseCaseProtocol = {
        GetEventsUseCase(repository: eventRepository)
    }()

    lazy var addEventUseCase: AddEventUseCaseProtocol = {
        AddEventUseCase(repository: eventRepository)
    }()

    lazy var updateEventUseCase: UpdateEventUseCaseProtocol = {
        UpdateEventUseCase(repository: eventRepository)
    }()

    lazy var deleteEventUseCase: DeleteEventUseCaseProtocol = {
        DeleteEventUseCase(repository: eventRepository)
    }()

    lazy var searchEventsUseCase: SearchEventsUseCaseProtocol = {
        SearchEventsUseCase(repository: eventRepository)
    }()

    lazy var getEventStatisticsUseCase: GetEventStatisticsUseCaseProtocol = {
        GetEventStatisticsUseCase(repository: eventRepository)
    }()

    lazy var getEventsForDateUseCase: GetEventsForDateUseCaseProtocol = {
        GetEventsForDateUseCase(repository: eventRepository)
    }()

    lazy var getSettingsUseCase: GetSettingsUseCaseProtocol = {
        GetSettingsUseCase_Settings(repository: settingsRepository)
    }()

    lazy var saveSettingsUseCase: SaveSettingsUseCaseProtocol = {
        SaveSettingsUseCase(repository: settingsRepository)
    }()

    // MARK: - ViewModels
    func makeEventsListViewModel() -> EventsListViewModel {
        EventsListViewModel(
            getEventsUseCase: getEventsUseCase,
            updateEventUseCase: updateEventUseCase,
            deleteEventUseCase: deleteEventUseCase,
            searchEventsUseCase: searchEventsUseCase,
            notificationService: notificationService
        )
    }

    func makeScanViewModel() -> ScanViewModel {
        ScanViewModel(
            textRecognitionService: textRecognitionService,
            textEventParserService: textEventParserService,
            addEventUseCase: addEventUseCase,
            notificationService: notificationService
        )
    }

    func makeTextInputViewModel() -> TextInputViewModel {
        TextInputViewModel(
            textRecognitionService: textRecognitionService,
            addEventUseCase: addEventUseCase
        )
    }

    func makeContentViewModel() -> ContentViewModel {
        ContentViewModel(getEventsUseCase: getEventsUseCase,
                         addEventUseCase: addEventUseCase,
                         updateEventUseCase: updateEventUseCase,
                         deleteEventUseCase: deleteEventUseCase,
                         textRecognitionService: textRecognitionService,
                         textParser: textEventParserService,
                         notificationService: notificationService
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            getSettingsUseCase: getSettingsUseCase,
            saveSettingsUseCase: saveSettingsUseCase
        )
    }

    // Private init for singleton
    private init() {}
}
