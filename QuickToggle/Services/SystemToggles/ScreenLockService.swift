import Foundation
import Cocoa
import os.log

/// Service for locking the screen
class ScreenLockService: BaseObservableToggleService {
    init() {
        super.init(toggleType: .screenLock)
        
        // Screen lock is always available
        Task { @MainActor in
            self.currentAvailability = true
            self.currentPermission = true
        }
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        // Screen lock is an action, not a toggle state
        return false
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        // This shouldn't be called for action items
        throw ToggleError.invalidState
    }
    
    override func isAvailable() async -> Bool {
        // Screen lock is always available
        return true
    }
    
    override func hasPermission() async -> Bool {
        // No special permissions needed
        return true
    }
    
    override func requestPermission() async -> Bool {
        // No permissions to request
        return true
    }
    
    override func performAction() async throws {
        Logger.toggles.info("Performing screen lock action")
        
        // Method 1: Use IOKit to lock the screen (most reliable)
        let result = await lockScreenWithIOKit()
        
        if !result {
            // Method 2: Fallback to menu bar command
            Logger.toggles.warning("IOKit method failed, trying menu bar method")
            try await lockScreenWithMenuBar()
        }
        
        Logger.toggles.info("Screen lock completed successfully")
    }
    
    // MARK: - Private Methods
    
    private func lockScreenWithIOKit() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Use CGSession to lock the screen
                let ioKitPath = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
                let task = Process()
                task.launchPath = ioKitPath
                task.arguments = ["-suspend"]
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    if task.terminationStatus == 0 {
                        Logger.toggles.debug("Screen locked successfully with IOKit")
                        continuation.resume(returning: true)
                    } else {
                        Logger.toggles.error("IOKit lock failed with status: \(task.terminationStatus)")
                        continuation.resume(returning: false)
                    }
                } catch {
                    Logger.toggles.error("Failed to execute IOKit lock: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func lockScreenWithMenuBar() async throws {
        // Use AppleScript to trigger lock screen via menu bar
        let script = """
            tell application "System Events"
                keystroke "q" using {command down, control down}
            end tell
            """
        
        guard let appleScript = NSAppleScript(source: script) else {
            throw ToggleError.systemError(NSError(
                domain: "ScreenLockService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create AppleScript"]
            ))
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    Logger.toggles.error("AppleScript error: \(errorMessage)")
                    continuation.resume(throwing: ToggleError.systemError(NSError(
                        domain: "ScreenLockService",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                    )))
                } else {
                    Logger.toggles.debug("Screen locked successfully with AppleScript")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Screen Lock service")
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Screen Lock service")
    }
}