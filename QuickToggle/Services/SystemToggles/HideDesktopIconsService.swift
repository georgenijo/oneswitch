import Foundation
import Cocoa
import os.log

/// Service for managing desktop icon visibility
class HideDesktopIconsService: BaseObservableToggleService {
    // Defaults key for CreateDesktop preference
    private let finderBundleID = "com.apple.finder"
    private let createDesktopKey = "CreateDesktop"
    
    // Timer for state monitoring
    private var stateCheckTimer: Timer?
    
    // Background queue for polling
    private let pollingQueue = DispatchQueue(label: "com.quicktoggle.desktop-polling", qos: .background)
    
    // Synchronization for state changes
    @MainActor private var isChangingState = false
    
    init() {
        super.init(toggleType: .desktopIcons)
        checkInitialState()
    }
    
    // MARK: - State Management
    
    private func checkInitialState() {
        Task {
            do {
                let isHidden = try await getCurrentDesktopIconsState()
                await MainActor.run {
                    self.currentState = isHidden
                    self.currentAvailability = true
                    self.currentPermission = true
                }
                Logger.toggles.info("Desktop icons initial state: \(isHidden ? "hidden" : "visible")")
            } catch {
                Logger.toggles.error("Failed to get initial desktop icons state: \(error.localizedDescription)")
                await MainActor.run {
                    self.currentAvailability = false
                }
            }
        }
    }
    
    private func getCurrentDesktopIconsState() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Read the CreateDesktop preference
                let task = Process()
                task.launchPath = "/usr/bin/defaults"
                task.arguments = ["read", self.finderBundleID, self.createDesktopKey]
                
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = Pipe()
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    // If the key doesn't exist, defaults returns an error and desktop icons are shown (default)
                    // If it exists and is 0, desktop icons are hidden
                    // If it exists and is 1, desktop icons are shown
                    if task.terminationStatus != 0 {
                        // Key doesn't exist, desktop icons are visible by default
                        continuation.resume(returning: false)
                    } else {
                        let isHidden = output == "0"
                        continuation.resume(returning: isHidden)
                    }
                } catch {
                    Logger.toggles.error("Failed to read desktop icons state: \(error.localizedDescription)")
                    continuation.resume(throwing: ToggleError.systemError(error))
                }
            }
        }
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        return try await getCurrentDesktopIconsState()
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        // Prevent race conditions
        await MainActor.run {
            isChangingState = true
        }
        
        defer {
            Task { @MainActor in
                isChangingState = false
            }
        }
        
        // enabled = true means hide icons, enabled = false means show icons
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                // First, set the defaults value
                let task = Process()
                task.launchPath = "/usr/bin/defaults"
                task.arguments = ["write", self.finderBundleID, self.createDesktopKey, "-bool", enabled ? "false" : "true"]
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    if task.terminationStatus != 0 {
                        continuation.resume(throwing: ToggleError.systemError(NSError(
                            domain: "HideDesktopIconsService",
                            code: Int(task.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "Failed to write desktop preference"]
                        )))
                        return
                    }
                    
                    // Now restart Finder to apply the change
                    let restartTask = Process()
                    restartTask.launchPath = "/usr/bin/killall"
                    restartTask.arguments = ["Finder"]
                    
                    try restartTask.run()
                    restartTask.waitUntilExit()
                    
                    // Give Finder a moment to restart
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    Logger.toggles.info("Successfully set desktop icons to \(enabled ? "hidden" : "visible")")
                    continuation.resume()
                } catch {
                    Logger.toggles.error("Failed to toggle desktop icons: \(error.localizedDescription)")
                    continuation.resume(throwing: ToggleError.systemError(error))
                }
            }
        }
        
        // Update our state
        await MainActor.run {
            self.currentState = enabled
        }
    }
    
    override func hasPermission() async -> Bool {
        // Desktop icon control doesn't require special permissions
        return true
    }
    
    override func requestPermission() async -> Bool {
        // No special permissions needed
        return true
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Hide Desktop Icons service")
        
        // Start polling on background queue
        pollingQueue.async { [weak self] in
            self?.stateCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                // Skip if we're changing state
                Task { @MainActor in
                    if self.isChangingState {
                        return
                    }
                }
                
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    do {
                        let isHidden = try await self.getCurrentDesktopIconsState()
                        await MainActor.run {
                            if isHidden != self.currentState {
                                Logger.toggles.info("Desktop icons state changed externally to \(isHidden ? "hidden" : "visible")")
                                self.currentState = isHidden
                            }
                        }
                    } catch {
                        Logger.toggles.error("Failed to check desktop icons state: \(error.localizedDescription)")
                    }
                }
            }
            // Keep the run loop active on this background queue
            RunLoop.current.run()
        }
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Hide Desktop Icons service")
        
        pollingQueue.async { [weak self] in
            self?.stateCheckTimer?.invalidate()
            self?.stateCheckTimer = nil
        }
    }
    
    // MARK: - Error Handling
    
    enum HideDesktopIconsError: LocalizedError {
        case finderRestartFailed
        case unsupportedOS
        
        var errorDescription: String? {
            switch self {
            case .finderRestartFailed:
                return "Failed to restart Finder"
            case .unsupportedOS:
                return "Desktop icon control is not supported on this version of macOS"
            }
        }
    }
}