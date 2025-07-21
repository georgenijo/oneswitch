import Foundation
import os.log

/// Mock implementation of ToggleServiceProtocol for testing and development
class MockToggleService: ToggleServiceProtocol {
    let toggleType: ToggleType
    private var currentState: Bool = false
    private let delay: TimeInterval
    
    init(toggleType: ToggleType, initialState: Bool = false, delay: TimeInterval = 0.5) {
        self.toggleType = toggleType
        self.currentState = initialState
        self.delay = delay
        Logger.toggles.debug("Created mock service for \(toggleType.displayName)")
    }
    
    func isEnabled() async throws -> Bool {
        // Simulate network/system delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        Logger.toggles.debug("Mock: \(self.toggleType.displayName) is \(self.currentState ? "enabled" : "disabled")")
        return currentState
    }
    
    func setEnabled(_ enabled: Bool) async throws {
        // Simulate network/system delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Simulate random failures for testing
        if Int.random(in: 0..<10) == 0 {
            Logger.toggles.error("Mock: Simulated failure for \(self.toggleType.displayName)")
            throw ToggleError.systemError(NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated failure"]))
        }
        
        currentState = enabled
        Logger.toggles.info("Mock: Set \(self.toggleType.displayName) to \(enabled ? "enabled" : "disabled")")
    }
    
    func isAvailable() async -> Bool {
        // Simulate some toggles being unavailable
        switch toggleType {
        case .trueTone:
            return false // Simulate True Tone not available
        case .lowPowerMode:
            return false // Simulate Low Power Mode not available on desktop
        default:
            return true
        }
    }
    
    func hasPermission() async -> Bool {
        // Simulate permission requirements
        switch toggleType {
        case .bluetooth, .wifi:
            return true // These typically need permissions
        default:
            return true
        }
    }
    
    func requestPermission() async -> Bool {
        // Simulate permission request
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        Logger.toggles.info("Mock: Permission granted for \(self.toggleType.displayName)")
        return true
    }
    
    func performAction() async throws {
        guard toggleType.isAction else {
            throw ToggleError.invalidState
        }
        
        // Simulate action delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        Logger.toggles.info("Mock: Performed action \(self.toggleType.displayName)")
        
        // Simulate specific actions
        switch toggleType {
        case .screenLock:
            Logger.toggles.debug("Mock: Would lock screen")
        case .emptyTrash:
            Logger.toggles.debug("Mock: Would empty trash")
        case .screenSaver:
            Logger.toggles.debug("Mock: Would activate screen saver")
        default:
            break
        }
    }
}

/// Mock implementation of SystemToggleService for testing
class MockSystemToggleService: SystemToggleService {
    private var services: [ToggleType: MockToggleService] = [:]
    
    init() {
        // Initialize mock services for all toggle types
        for toggleType in ToggleType.allCases {
            services[toggleType] = MockToggleService(toggleType: toggleType)
        }
    }
    
    func getCurrentState(for type: ToggleType) async throws -> Bool {
        guard let service = services[type] else {
            throw ToggleError.notSupported(type)
        }
        return try await service.isEnabled()
    }
    
    func setState(_ enabled: Bool, for type: ToggleType) async throws {
        guard let service = services[type] else {
            throw ToggleError.notSupported(type)
        }
        try await service.setEnabled(enabled)
    }
    
    func isAvailable(for type: ToggleType) async -> Bool {
        guard let service = services[type] else {
            return false
        }
        return await service.isAvailable()
    }
    
    func hasPermission(for type: ToggleType) async -> Bool {
        guard let service = services[type] else {
            return false
        }
        return await service.hasPermission()
    }
}