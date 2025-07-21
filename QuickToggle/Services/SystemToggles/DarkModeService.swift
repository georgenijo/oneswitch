import Foundation
import Cocoa
import os.log

/// Service for managing macOS Dark Mode
class DarkModeService: BaseObservableToggleService {
    // AppleScript sources
    private let getStateScriptSource = """
        tell application "System Events"
            tell appearance preferences
                return dark mode
            end tell
        end tell
        """
    
    private let setStateScriptTemplate = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to %@
            end tell
        end tell
        """
    
    // Compiled scripts (cached for performance)
    private var getStateScript: NSAppleScript?
    private var setStateTrueScript: NSAppleScript?
    private var setStateFalseScript: NSAppleScript?
    
    // Appearance observation
    private var appearanceObserver: NSKeyValueObservation?
    
    init() {
        super.init(toggleType: .darkMode)
        compileScripts()
        checkInitialState()
    }
    
    // MARK: - Script Compilation
    
    private func compileScripts() {
        Logger.toggles.debug("Compiling Dark Mode AppleScripts")
        
        // Compile get state script
        getStateScript = NSAppleScript(source: getStateScriptSource)
        if getStateScript?.compileAndReturnError(nil) == false {
            Logger.toggles.error("Failed to compile Dark Mode get state script")
            getStateScript = nil
        }
        
        // Compile set state scripts
        let setTrueSource = setStateScriptTemplate.replacingOccurrences(of: "%@", with: "true")
        setStateTrueScript = NSAppleScript(source: setTrueSource)
        if setStateTrueScript?.compileAndReturnError(nil) == false {
            Logger.toggles.error("Failed to compile Dark Mode set true script")
            setStateTrueScript = nil
        }
        
        let setFalseSource = setStateScriptTemplate.replacingOccurrences(of: "%@", with: "false")
        setStateFalseScript = NSAppleScript(source: setFalseSource)
        if setStateFalseScript?.compileAndReturnError(nil) == false {
            Logger.toggles.error("Failed to compile Dark Mode set false script")
            setStateFalseScript = nil
        }
    }
    
    // MARK: - State Management
    
    private func checkInitialState() {
        Task {
            do {
                let isDarkMode = try await getCurrentDarkModeState()
                await MainActor.run {
                    self.currentState = isDarkMode
                    self.currentAvailability = true
                    self.currentPermission = true // Will be updated when we check
                }
                Logger.toggles.info("Dark Mode initial state: \(isDarkMode ? "enabled" : "disabled")")
            } catch {
                Logger.toggles.error("Failed to get initial Dark Mode state: \(error.localizedDescription)")
                await MainActor.run {
                    self.currentAvailability = false
                }
            }
        }
    }
    
    private func getCurrentDarkModeState() async throws -> Bool {
        guard let script = getStateScript else {
            throw ToggleError.notSupported(.darkMode)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let result = script.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    Logger.toggles.error("AppleScript error: \(errorMessage)")
                    continuation.resume(throwing: ToggleError.systemError(NSError(
                        domain: "DarkModeService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                    )))
                    return
                }
                
                let isDarkMode = result.booleanValue
                continuation.resume(returning: isDarkMode)
            }
        }
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        return try await getCurrentDarkModeState()
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        // Use cached scripts
        guard let script = enabled ? setStateTrueScript : setStateFalseScript else {
            throw ToggleError.notSupported(.darkMode)
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                _ = script.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    Logger.toggles.error("AppleScript error: \(errorMessage)")
                    
                    // Check if it's a permission error
                    if errorMessage.contains("not allowed") {
                        continuation.resume(throwing: ToggleError.permissionDenied(.darkMode))
                    } else {
                        continuation.resume(throwing: ToggleError.systemError(NSError(
                            domain: "DarkModeService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )))
                    }
                    return
                }
                
                Logger.toggles.info("Successfully set Dark Mode to \(enabled ? "enabled" : "disabled")")
                continuation.resume()
            }
        }
        
        // Update our state
        await MainActor.run {
            self.currentState = enabled
        }
    }
    
    override func hasPermission() async -> Bool {
        // Check if we can execute AppleScript for System Events
        // This is a simplified check - real implementation would use proper authorization APIs
        return true
    }
    
    override func requestPermission() async -> Bool {
        // In a real implementation, this would guide the user to System Preferences
        // For now, we'll return true as AppleScript permissions are usually granted
        Logger.toggles.info("Requesting Dark Mode permission")
        
        // Show alert directing to System Preferences if needed
        await MainActor.run {
            if !self.currentPermission {
                self.showPermissionAlert()
            }
        }
        
        return true
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Dark Mode service")
        
        await MainActor.run {
            // Observe appearance changes
            self.appearanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    // Check if appearance actually changed
                    let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    if isDarkMode != self.currentState {
                        Logger.toggles.info("System appearance changed to \(isDarkMode ? "dark" : "light")")
                        self.currentState = isDarkMode
                    }
                }
            }
        }
        
        // Check initial permission status
        await checkPermissionStatus()
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Dark Mode service")
        
        await MainActor.run {
            self.appearanceObserver?.invalidate()
            self.appearanceObserver = nil
        }
    }
    
    // MARK: - Permission Handling
    
    private func checkPermissionStatus() async {
        // In production, check actual AppleEvents permission
        // For now, assume we have permission
        await MainActor.run {
            self.currentPermission = true
        }
    }
    
    @MainActor
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = "QuickToggle needs permission to control System Events to toggle Dark Mode. Please grant permission in System Preferences > Security & Privacy > Privacy > Automation."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Preferences to Privacy > Automation
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Error Handling
    
    enum DarkModeError: LocalizedError {
        case scriptCompilationFailed
        case scriptExecutionFailed(String)
        case permissionDenied
        case unsupportedOS
        
        var errorDescription: String? {
            switch self {
            case .scriptCompilationFailed:
                return "Failed to compile Dark Mode control script"
            case .scriptExecutionFailed(let message):
                return "Failed to execute Dark Mode control: \(message)"
            case .permissionDenied:
                return "Permission denied to control System Events"
            case .unsupportedOS:
                return "Dark Mode control is not supported on this version of macOS"
            }
        }
    }
}