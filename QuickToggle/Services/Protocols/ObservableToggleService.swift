import Foundation
import Combine

/// Protocol for toggle services that provide observable state changes
protocol ObservableToggleService: ToggleServiceProtocol {
    /// Publisher that emits the current state whenever it changes
    var statePublisher: AnyPublisher<Bool, Never> { get }
    
    /// Publisher that emits availability changes
    var availabilityPublisher: AnyPublisher<Bool, Never> { get }
    
    /// Publisher that emits permission status changes
    var permissionPublisher: AnyPublisher<Bool, Never> { get }
}

/// Base implementation for observable toggle services
class BaseObservableToggleService: ObservableToggleService, ServiceLifecycle {
    let toggleType: ToggleType
    
    // Publishers
    private let stateSubject = CurrentValueSubject<Bool, Never>(false)
    private let availabilitySubject = CurrentValueSubject<Bool, Never>(true)
    private let permissionSubject = CurrentValueSubject<Bool, Never>(false)
    
    var statePublisher: AnyPublisher<Bool, Never> {
        stateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var availabilityPublisher: AnyPublisher<Bool, Never> {
        availabilitySubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var permissionPublisher: AnyPublisher<Bool, Never> {
        permissionSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    // State tracking
    internal var currentState: Bool {
        get { stateSubject.value }
        set { stateSubject.send(newValue) }
    }
    
    internal var currentAvailability: Bool {
        get { availabilitySubject.value }
        set { availabilitySubject.send(newValue) }
    }
    
    internal var currentPermission: Bool {
        get { permissionSubject.value }
        set { permissionSubject.send(newValue) }
    }
    
    init(toggleType: ToggleType) {
        self.toggleType = toggleType
    }
    
    // MARK: - ToggleServiceProtocol
    
    func isEnabled() async throws -> Bool {
        return currentState
    }
    
    func setEnabled(_ enabled: Bool) async throws {
        // Subclasses override to implement actual toggle
        fatalError("Subclasses must implement setEnabled")
    }
    
    func isAvailable() async -> Bool {
        return currentAvailability
    }
    
    func hasPermission() async -> Bool {
        return currentPermission
    }
    
    func requestPermission() async -> Bool {
        // Subclasses override to implement permission request
        return false
    }
    
    func performAction() async throws {
        guard toggleType.isAction else {
            throw ToggleError.invalidState
        }
        // Subclasses override for action implementation
    }
    
    // MARK: - ServiceLifecycle
    
    func start() async {
        // Subclasses override to start observing
    }
    
    func stop() async {
        // Subclasses override to stop observing
    }
}