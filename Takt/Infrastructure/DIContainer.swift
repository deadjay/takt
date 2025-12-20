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
    
    // MARK: - Services
    
    lazy var textRecognitionService: TextRecognitionServiceProtocol = {
        DefaultTextRecognitionService()
    }()
    
    lazy var textEventParserService: TextEventParserServiceProtocol = {
        TextEventParser()
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
    
    // MARK: - ViewModels
    func makeEventsListViewModel() -> EventsListViewModel {
        EventsListViewModel(
            getEventsUseCase: getEventsUseCase,
            deleteEventUseCase: deleteEventUseCase,
            searchEventsUseCase: searchEventsUseCase
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
                         textParser: textEventParserService
        )
    }

    // Private init for singleton
    private init() {}
}
