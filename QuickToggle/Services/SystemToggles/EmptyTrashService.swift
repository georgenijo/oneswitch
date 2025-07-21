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
        // Basic trash operations don't need special permissions
        return true
    }
    
    override func requestPermission() async -> Bool {
        // No permissions to request
        return true
    }
    
    override func performAction() async throws {
        Logger.toggles.info("Performing empty trash action")
        
        // Update count first
        await updateTrashCount()
        
        // Check if trash is already empty
        if cachedItemCount == 0 {
            Logger.toggles.info("Trash is already empty")
            // Could show a notification here
            return
        }
        
        // Show confirmation dialog
        let shouldEmpty = await showConfirmationDialog()
        
        if shouldEmpty {
            Logger.toggles.info("User confirmed empty trash")
            
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
    
    private func updateTrashCount() async {
        let count = await countTrashItems()
        await MainActor.run {
            self.cachedItemCount = count
            self.lastCountUpdate = Date()
        }
        Logger.toggles.debug("Trash item count updated: \(count)")
    }
    
    private func countTrashItems() async -> Int {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fileManager = FileManager.default
                let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first
                
                guard let trashURL = trashURL else {
                    Logger.toggles.error("Could not locate trash directory")
                    continuation.resume(returning: 0)
                    return
                }
                
                do {
                    let items = try fileManager.contentsOfDirectory(
                        at: trashURL,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                    )
                    continuation.resume(returning: items.count)
                } catch {
                    Logger.toggles.error("Failed to count trash items: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
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
    
    // MARK: - ServiceLifecycle
    
    override func start() async {
        Logger.toggles.info("Starting Empty Trash service")
        await updateTrashCount()
    }
    
    override func stop() async {
        Logger.toggles.info("Stopping Empty Trash service")
    }
}