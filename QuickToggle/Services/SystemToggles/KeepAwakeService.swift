import Foundation
import IOKit.pwr_mgt
import os.log

/// Service for preventing system sleep
class KeepAwakeService: BaseObservableToggleService {
    // Power assertion management
    private var assertionID: IOPMAssertionID = 0
    private var assertionStartTime: Date?
    private let assertionLock = NSLock()
    
    // Configurable options
    private let preventDisplaySleep: Bool = false // Could be made configurable later
    private let assertionName = "QuickToggle Keep Awake"
    
    init() {
        super.init(toggleType: .keepAwake)
        checkInitialState()
    }
    
    // MARK: - State Management
    
    private func checkInitialState() {
        // On startup, we don't have an active assertion
        // If we want to persist state across restarts, we'd need to store this in UserDefaults
        Task { @MainActor in
            self.currentState = false
            self.currentAvailability = true
            self.currentPermission = true // No special permissions needed
        }
        
        Logger.toggles.info("Keep Awake initial state: disabled")
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        // Simple check - if we have a valid assertion ID, we're active
        assertionLock.lock()
        defer { assertionLock.unlock() }
        return assertionID != 0
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        if enabled {
            try await createAssertion()
        } else {
            await releaseAssertion()
        }
    }
    
    private func createAssertion() async throws {
        // Release any existing assertion first
        assertionLock.lock()
        let hasExisting = assertionID != 0
        assertionLock.unlock()
        
        if hasExisting {
            await releaseAssertion()
        }
        
        // Determine assertion type based on configuration
        let assertionType = preventDisplaySleep 
            ? kIOPMAssertPreventUserIdleDisplaySleep 
            : kIOPMAssertPreventUserIdleSystemSleep
        
        // Create the assertion
        assertionLock.lock()
        defer { assertionLock.unlock() }
        
        let result = IOPMAssertionCreateWithName(
            assertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            assertionName as CFString,
            &assertionID
        )
        
        if result == kIOReturnSuccess {
            Logger.toggles.info("Successfully created power assertion with ID: \(self.assertionID)")
            
            await MainActor.run {
                self.assertionStartTime = Date()
                self.currentState = true
            }
        } else {
            Logger.toggles.error("Failed to create power assertion: \(result)")
            
            // Convert IOReturn to error with more context
            let assertionTypeStr = preventDisplaySleep ? "NoDisplaySleep" : "NoIdleSleep"
            throw ToggleError.systemError(NSError(
                domain: "KeepAwakeService",
                code: Int(result),
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create power assertion of type '\(assertionTypeStr)'",
                    "IOReturnCode": result,
                    "AssertionType": assertionTypeStr
                ]
            ))
        }
    }
    
    private func releaseAssertion() async {
        assertionLock.lock()
        let currentID = assertionID
        guard currentID != 0 else {
            assertionLock.unlock()
            return
        }
        assertionLock.unlock()
        
        let result = IOPMAssertionRelease(currentID)
        
        if result == kIOReturnSuccess {
            Logger.toggles.info("Successfully released power assertion")
        } else {
            Logger.toggles.error("Failed to release power assertion: \(result), AssertionID: \(currentID)")
        }
        
        assertionLock.lock()
        assertionID = 0
        assertionLock.unlock()
        
        await MainActor.run {
            self.assertionStartTime = nil
            self.currentState = false
        }
    }
    
    override func hasPermission() async -> Bool {
        // Keep Awake doesn't require special permissions
        return true
    }
    
    override func requestPermission() async -> Bool {
        // No permissions to request
        return true
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Keep Awake service")
        
        // Since we release assertions on stop, we start fresh each time
        // No need to verify previous assertions
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Keep Awake service")
        
        // Release any active assertion when service stops
        await releaseAssertion()
    }
    
    // MARK: - Additional Features
    
    /// Get the duration the assertion has been active
    func getActiveDuration() -> TimeInterval? {
        guard let startTime = assertionStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Get a formatted string showing how long Keep Awake has been active
    func getActiveDurationString() -> String? {
        guard let duration = getActiveDuration() else { return nil }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: duration)
    }
    
    // MARK: - Debug Information
    
    func getAssertionInfo() async -> String {
        assertionLock.lock()
        let currentID = assertionID
        assertionLock.unlock()
        
        guard currentID != 0 else { return "No active assertion" }
        
        let duration = getActiveDurationString() ?? "Unknown"
        return "Assertion ID: \(currentID), Duration: \(duration)"
    }
}

