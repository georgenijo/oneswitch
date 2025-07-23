import Foundation
import os.log

/// Protocol for services that have lifecycle management
protocol ServiceLifecycle {
    func start() async
    func stop() async
}

/// Manages all toggle services and provides a unified interface
@MainActor
class ToggleServiceManager {
    static let shared = ToggleServiceManager()
    
    private var services: [ToggleType: ToggleServiceProtocol] = [:]
    private let systemService: SystemToggleService
    
    /// Initialize with optional custom services
    /// - Parameters:
    ///   - systemService: Optional system service (defaults to mock)
    ///   - serviceRegistry: Optional pre-configured services
    init(systemService: SystemToggleService? = nil,
         serviceRegistry: [ToggleType: ToggleServiceProtocol]? = nil) {
        self.systemService = systemService ?? MockSystemToggleService()
        
        if let registry = serviceRegistry {
            self.services = registry
        }
        
        Logger.toggles.info("Initializing ToggleServiceManager")
        setupDefaultServices()
    }
    
    private func setupDefaultServices() {
        // Only setup mock services for types that don't have real implementations
        for toggleType in ToggleType.allCases {
            if services[toggleType] == nil {
                services[toggleType] = MockToggleService(toggleType: toggleType)
            }
        }
        
        Logger.toggles.info("Initialized \(self.services.count) toggle services")
    }
    
    /// Register a service for a specific toggle type
    /// - Parameters:
    ///   - service: The service implementation
    ///   - type: The toggle type this service handles
    func register(_ service: ToggleServiceProtocol, for type: ToggleType) {
        Logger.toggles.info("Registering service for \(type.displayName)")
        
        // Stop existing service if it has lifecycle
        if let existingService = services[type] as? ServiceLifecycle {
            Task {
                await existingService.stop()
            }
        }
        
        services[type] = service
        
        // Start new service if it has lifecycle
        if let lifecycleService = service as? ServiceLifecycle {
            Task {
                await lifecycleService.start()
                Logger.toggles.info("Started service for \(type.displayName)")
            }
        }
    }
    
    /// Unregister a service for a specific toggle type
    /// - Parameter type: The toggle type to unregister
    func unregister(_ type: ToggleType) {
        Logger.toggles.info("Unregistering service for \(type.displayName)")
        
        if let service = services[type] as? ServiceLifecycle {
            Task {
                await service.stop()
            }
        }
        
        services.removeValue(forKey: type)
        
        // Replace with mock service
        services[type] = MockToggleService(toggleType: type)
    }
    
    /// Get a service for a specific toggle type
    func service(for type: ToggleType) -> ToggleServiceProtocol? {
        return services[type]
    }
    
    /// Get the current state of a toggle
    func getCurrentState(for type: ToggleType) async throws -> Bool {
        guard let service = services[type] else {
            throw ToggleError.notSupported(type)
        }
        return try await service.isEnabled()
    }
    
    /// Set the state of a toggle
    func setState(_ enabled: Bool, for type: ToggleType) async throws {
        guard let service = services[type] else {
            throw ToggleError.notSupported(type)
        }
        
        // Check permission first
        if await !service.hasPermission() {
            let granted = await service.requestPermission()
            if !granted {
                throw ToggleError.permissionDenied(type)
            }
        }
        
        try await service.setEnabled(enabled)
    }
    
    /// Perform an action toggle
    func performAction(for type: ToggleType) async throws {
        guard let service = services[type] else {
            throw ToggleError.notSupported(type)
        }
        
        guard type.isAction else {
            throw ToggleError.invalidState
        }
        
        try await service.performAction()
    }
    
    /// Check if a toggle is available
    func isAvailable(for type: ToggleType) async -> Bool {
        guard let service = services[type] else {
            return false
        }
        return await service.isAvailable()
    }
    
    /// Get availability status for all toggles
    func getAvailabilityStatus() async -> [ToggleType: Bool] {
        var status: [ToggleType: Bool] = [:]
        
        await withTaskGroup(of: (ToggleType, Bool).self) { group in
            for (type, service) in services {
                group.addTask {
                    let available = await service.isAvailable()
                    return (type, available)
                }
            }
            
            for await (type, available) in group {
                status[type] = available
            }
        }
        
        return status
    }
    
    /// Start all services that have lifecycle management
    func startAllServices() async {
        Logger.toggles.info("Starting all services")
        
        await withTaskGroup(of: Void.self) { group in
            for service in services.values {
                if let lifecycleService = service as? ServiceLifecycle {
                    group.addTask {
                        await lifecycleService.start()
                    }
                }
            }
        }
    }
    
    /// Stop all services that have lifecycle management
    func stopAllServices() async {
        Logger.toggles.info("Stopping all services")
        
        await withTaskGroup(of: Void.self) { group in
            for service in services.values {
                if let lifecycleService = service as? ServiceLifecycle {
                    group.addTask {
                        await lifecycleService.stop()
                    }
                }
            }
        }
    }
}