import Foundation
import Cocoa
import os.log

/// Service for emptying the system trash
class EmptyTrashService: BaseObservableToggleService {
    // Cache for trash item count
    private var cachedItemCount: Int = 0
    private var lastCountUpdate: Date?
    private let countCacheTimeout: TimeInterval = 2.0 // Refresh count every 2 seconds
    
    init() {
        super.init(toggleType: .emptyTrash)
        
        // Empty Trash is always available
        Task { @MainActor in
            self.currentAvailability = true
            self.currentPermission = true
        }
        
        // Initial trash count
        Task {
            await updateTrashCount()
        }
    }
    
    // MARK: - ToggleServiceProtocol
    
    override func isEnabled() async throws -> Bool {
        // Empty Trash is an action, not a toggle state
        return false
    }
    
    override func setEnabled(_ enabled: Bool) async throws {
        // This shouldn't be called for action items
        throw ToggleError.invalidState
    }
    
    override func isAvailable() async -> Bool {
        // Empty Trash is always available
        return true
    }
    
    override func hasPermission() async -> Bool {
        // Check if we can access trash
        return await checkTrashAccess()
    }
    
    override func requestPermission() async -> Bool {
        // Show permission dialog
        await MainActor.run {
            showTrashAccessAlert()
        }
        return false
    }
    
    override func performAction() async throws {
        Logger.toggles.info("Performing empty trash action")
        
        // Check permissions first
        if !(await checkTrashAccess()) {
            await MainActor.run {
                showTrashAccessAlert()
            }
            throw ToggleError.permissionDenied(.emptyTrash)
        }
        
        // Update count with error handling
        await updateTrashCount()
        
        // Check if trash is already empty
        if cachedItemCount == 0 {
            Logger.toggles.info("Trash is already empty")
            // Could show a notification here
            return
        }
        
        // Check preference for confirmation
        let preferences = PreferencesManager.shared.loadPreferences()
        let skipConfirmation = preferences.skipEmptyTrashConfirmation
        
        var shouldEmpty = true
        
        if !skipConfirmation {
            shouldEmpty = await showConfirmationDialog()
        }
        
        if shouldEmpty {
            Logger.toggles.info("Emptying trash with \(self.cachedItemCount) items")
            
            // Try Finder method first (most reliable)
            let success = await emptyTrashWithFinder()
            
            if !success {
                // Fallback to FileManager method
                Logger.toggles.warning("Finder method failed, trying FileManager")
                try await emptyTrashWithFileManager()
            }
            
            // Update count after emptying
            await updateTrashCount()
            
            Logger.toggles.info("Empty trash completed successfully")
        } else {
            Logger.toggles.info("User cancelled empty trash")
        }
    }
    
    // MARK: - Public Methods
    
    func getTrashItemCount() async -> Int {
        // Check if we need to update the cache
        if let lastUpdate = lastCountUpdate,
           Date().timeIntervalSince(lastUpdate) < countCacheTimeout {
            return cachedItemCount
        }
        
        // Update and return fresh count
        await updateTrashCount()
        return cachedItemCount
    }
    
    // MARK: - Private Methods
    
    private func checkTrashAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fileManager = FileManager.default
                guard let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Check if we can read the trash directory
                let isReadable = fileManager.isReadableFile(atPath: trashURL.path)
                Logger.toggles.debug("Trash access check: \(isReadable ? "granted" : "denied")")
                continuation.resume(returning: isReadable)
            }
        }
    }
    
    private func updateTrashCount() async {
        do {
            let count = try await countTrashItems()
            await MainActor.run {
                self.cachedItemCount = count
                self.lastCountUpdate = Date()
            }
            Logger.toggles.debug("Trash item count updated: \(count)")
        } catch {
            Logger.toggles.error("Failed to update trash count: \(error)")
            // Try Finder fallback
            let finderCount = await getTrashCountViaFinder()
            await MainActor.run {
                self.cachedItemCount = finderCount
                self.lastCountUpdate = Date()
            }
        }
    }
    
    private func countTrashItems() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fileManager = FileManager.default
                guard let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first else {
                    continuation.resume(throwing: ToggleError.systemError(NSError(
                        domain: "EmptyTrashService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not locate trash directory"]
                    )))
                    return
                }
                
                // Check access first
                guard fileManager.isReadableFile(atPath: trashURL.path) else {
                    Logger.toggles.error("Permission denied accessing trash directory")
                    continuation.resume(throwing: ToggleError.permissionDenied(.emptyTrash))
                    return
                }
                
                do {
                    // Remove .skipsHiddenFiles to count ALL items
                    let items = try fileManager.contentsOfDirectory(
                        at: trashURL,
                        includingPropertiesForKeys: nil,
                        options: [.skipsSubdirectoryDescendants]
                    )
                    continuation.resume(returning: items.count)
                } catch {
                    Logger.toggles.error("Failed to count trash items: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getTrashCountViaFinder() async -> Int {
        let script = """
            tell application "Finder"
                return count of items in trash
            end tell
            """
        
        guard let appleScript = NSAppleScript(source: script) else {
            Logger.toggles.error("Failed to create AppleScript for trash count")
            return 0
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let result = appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    Logger.toggles.error("AppleScript count error: \(errorMessage)")
                    continuation.resume(returning: 0)
                } else {
                    let count = Int(result.int32Value)
                    Logger.toggles.debug("Trash count via Finder: \(count)")
                    continuation.resume(returning: count)
                }
            }
        }
    }
    
    @MainActor
    private func showConfirmationDialog() async -> Bool {
        return await withCheckedContinuation { continuation in
            let alert = NSAlert()
            alert.messageText = "Empty Trash?"
            
            let itemText = cachedItemCount == 1 ? "item" : "items"
            alert.informativeText = "Are you sure you want to permanently delete \(cachedItemCount) \(itemText)?"
            
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Empty Trash")
            alert.addButton(withTitle: "Cancel")
            
            // Use non-blocking sheet if we have a window
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                alert.beginSheetModal(for: window) { response in
                    continuation.resume(returning: response == .alertFirstButtonReturn)
                }
            } else {
                // Fallback to modal
                let response = alert.runModal()
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }
    
    private func emptyTrashWithFinder() async -> Bool {
        let script = """
            tell application "Finder"
                empty trash
            end tell
            """
        
        guard let appleScript = NSAppleScript(source: script) else {
            Logger.toggles.error("Failed to create AppleScript for empty trash")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                _ = appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    
                    // Check for automation permission error (-1743)
                    if errorNumber == -1743 || errorMessage.contains("not allowed") {
                        Logger.toggles.error("Finder automation permission denied (error: \(errorNumber))")
                        Task { @MainActor in
                            self.showAutomationPermissionAlert()
                        }
                    } else {
                        Logger.toggles.error("AppleScript error: \(errorMessage) (error: \(errorNumber))")
                    }
                    continuation.resume(returning: false)
                } else {
                    Logger.toggles.debug("Trash emptied successfully with Finder")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    private func emptyTrashWithFileManager() async throws {
        let fileManager = FileManager.default
        let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first
        
        guard let trashURL = trashURL else {
            throw ToggleError.systemError(NSError(
                domain: "EmptyTrashService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not locate trash directory"]
            ))
        }
        
        let items = try fileManager.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: nil,
            options: []
        )
        
        var errors: [Error] = []
        
        for item in items {
            do {
                try fileManager.removeItem(at: item)
                Logger.toggles.debug("Removed item: \(item.lastPathComponent)")
            } catch {
                Logger.toggles.error("Failed to remove \(item.lastPathComponent): \(error.localizedDescription)")
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            // Some items couldn't be deleted
            throw ToggleError.systemError(NSError(
                domain: "EmptyTrashService",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Could not delete \(errors.count) items",
                    "FailedItems": errors.count
                ]
            ))
        }
        
        Logger.toggles.info("Trash emptied successfully with FileManager")
    }
    
    @MainActor
    private func showAutomationPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = "QuickToggle needs permission to control Finder to empty the trash. Please allow access in System Settings > Privacy & Security > Automation."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        // Use non-blocking sheet if we have a window
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    // Open Automation settings
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        } else {
            // Fallback to modal
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    @MainActor
    private func showTrashAccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Trash Access Required"
        alert.informativeText = "QuickToggle needs permission to access your Trash folder. Please grant Full Disk Access in System Settings > Privacy & Security > Full Disk Access."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        // Use non-blocking sheet if we have a window
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    // Open Full Disk Access settings
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FullDiskAccess") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        } else {
            // Fallback to modal
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FullDiskAccess") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Empty Trash service")
        await updateTrashCount()
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Empty Trash service")
    }
}