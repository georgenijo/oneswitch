import Foundation
import Combine
import AppKit
import os.log

@MainActor
class ToggleViewModel: ObservableObject {
    @Published private(set) var toggles: [Toggle] = []
    @Published private(set) var isLoading = false
    
    private var preferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    private let preferencesManager = PreferencesManager.shared
    
    init() {
        self.preferences = preferencesManager.loadPreferences()
        Logger.toggles.info("Initializing ToggleViewModel")
        loadToggles()
        setupObservers()
    }
    
    private func loadToggles() {
        Logger.toggles.debug("Loading toggles from preferences")
        isLoading = true
        
        Task {
            // Get enabled toggles in order
            let enabledTypes = preferences.enabledToggles
                .compactMap { toggleType in
                    preferences.toggleOrder.first { $0 == toggleType }
                }
            
            // Load toggle states and availability
            var loadedToggles: [Toggle] = []
            
            for toggleType in enabledTypes {
                let isAvailable = await ToggleServiceManager.shared.isAvailable(for: toggleType)
                let isEnabled = (try? await ToggleServiceManager.shared.getCurrentState(for: toggleType)) ?? false
                
                // Get custom title for dynamic toggles
                var customTitle: String? = nil
                if toggleType == .emptyTrash,
                   let service = ToggleServiceManager.shared.service(for: .emptyTrash) as? EmptyTrashService {
                    let count = await service.getTrashItemCount()
                    customTitle = count == 0 ? "Empty Trash (Empty)" : "Empty Trash (\(count) item\(count == 1 ? "" : "s"))"
                }
                
                loadedToggles.append(Toggle(
                    type: toggleType,
                    isEnabled: isEnabled,
                    isAvailable: isAvailable,
                    customTitle: customTitle
                ))
            }
            
            await MainActor.run {
                self.toggles = loadedToggles
                self.isLoading = false
                Logger.toggles.info("Loaded \(self.toggles.count) toggles")
                
                // Setup observers after toggles are loaded
                self.setupServiceObservers()
            }
        }
    }
    
    private func setupObservers() {
        // Observe preference changes
        NotificationCenter.default.publisher(for: Constants.Notifications.preferencesChanged)
            .sink { [weak self] _ in
                Logger.toggles.info("Preferences changed notification received")
                self?.preferences = self?.preferencesManager.loadPreferences() ?? UserPreferences.default
                self?.loadToggles()
            }
            .store(in: &cancellables)
        
        // Setup service state observers after toggles are loaded
        setupServiceObservers()
    }
    
    private func setupServiceObservers() {
        // Observe state changes from observable services
        for toggleType in preferences.enabledToggles {
            guard let service = ToggleServiceManager.shared.service(for: toggleType),
                  let observableService = service as? ObservableToggleService else {
                continue
            }
            
            // Subscribe to state changes
            observableService.statePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isEnabled in
                    self?.updateToggleState(toggleType, isEnabled: isEnabled)
                }
                .store(in: &cancellables)
            
            // Subscribe to availability changes
            observableService.availabilityPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isAvailable in
                    self?.updateToggleAvailability(toggleType, isAvailable: isAvailable)
                }
                .store(in: &cancellables)
        }
    }
    
    private func updateToggleState(_ type: ToggleType, isEnabled: Bool) {
        guard let index = toggles.firstIndex(where: { $0.type == type }) else { return }
        
        if toggles[index].isEnabled != isEnabled {
            Logger.toggles.debug("External state change detected for \(type.displayName): \(isEnabled)")
            toggles[index].isEnabled = isEnabled
        }
    }
    
    private func updateToggleAvailability(_ type: ToggleType, isAvailable: Bool) {
        guard let index = toggles.firstIndex(where: { $0.type == type }) else { return }
        
        if toggles[index].isAvailable != isAvailable {
            Logger.toggles.debug("Availability change for \(type.displayName): \(isAvailable)")
            toggles[index].isAvailable = isAvailable
        }
    }
    
    func toggle(_ toggle: Toggle) {
        guard let index = toggles.firstIndex(where: { $0.id == toggle.id }) else {
            Logger.toggles.error("Toggle not found: \(toggle.type.rawValue)")
            return
        }
        
        Logger.toggles.info("Toggling \(toggle.type.displayName) from \(toggle.isEnabled) to \(!toggle.isEnabled)")
        
        let newState = !toggle.isEnabled
        
        Task {
            do {
                // Update via service
                try await ToggleServiceManager.shared.setState(newState, for: toggle.type)
                
                // Update local state on success
                await MainActor.run {
                    self.toggles[index].isEnabled = newState
                    
                    // Post notification for state change
                    NotificationCenter.default.post(
                        name: Constants.Notifications.toggleStateChanged,
                        object: nil,
                        userInfo: ["toggleType": toggle.type, "isEnabled": newState]
                    )
                }
            } catch {
                Logger.toggles.error("Failed to toggle \(toggle.type.displayName): \(error.localizedDescription)")
                
                // Show error to user
                await MainActor.run {
                    self.showError(error, for: toggle.type)
                }
            }
        }
    }
    
    func performAction(_ toggle: Toggle) {
        Logger.toggles.info("Performing action: \(toggle.type.displayName)")
        
        Task {
            do {
                try await ToggleServiceManager.shared.performAction(for: toggle.type)
                Logger.toggles.info("Successfully performed action: \(toggle.type.displayName)")
            } catch {
                Logger.toggles.error("Failed to perform action \(toggle.type.displayName): \(error.localizedDescription)")
                // Show error to user
                await MainActor.run {
                    self.showError(error, for: toggle.type)
                }
            }
        }
    }
    
    func updatePreferences(_ newPreferences: UserPreferences) {
        Logger.toggles.info("Updating preferences")
        self.preferences = newPreferences
        loadToggles()
    }
    
    // MARK: - Error Handling
    
    private func showError(_ error: Error, for toggleType: ToggleType) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Toggle Failed"
        
        // Customize message based on error type
        if let toggleError = error as? ToggleError {
            alert.informativeText = toggleError.localizedDescription
            
            // Add recovery suggestion if available
            if let suggestion = toggleError.recoverySuggestion {
                alert.informativeText += "\n\n" + suggestion
            }
            
            // Add special handling for permission errors
            if case .permissionDenied(let type) = toggleError {
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "OK")
                
                // Handle button response
                if let window = NSApp.keyWindow ?? NSApp.windows.first {
                    alert.beginSheetModal(for: window) { response in
                        if response == .alertFirstButtonReturn {
                            // Open appropriate settings based on toggle type
                            self.openSystemSettings(for: type)
                        }
                    }
                } else {
                    // Fallback to non-sheet modal if no window available
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        self.openSystemSettings(for: toggleType)
                    }
                }
                return
            }
        } else {
            // Generic error message
            alert.informativeText = "Failed to toggle \(toggleType.displayName): \(error.localizedDescription)"
        }
        
        // Show alert
        if let window = NSApp.keyWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
    
    private func openSystemSettings(for toggleType: ToggleType) {
        var urlString: String?
        
        switch toggleType {
        case .darkMode:
            // Open Appearance settings
            urlString = "x-apple.systempreferences:com.apple.preference.general"
        default:
            // Open general System Preferences
            urlString = "x-apple.systempreferences:"
        }
        
        if let urlString = urlString, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Dynamic Updates
    
    func refreshDynamicToggles() async {
        // Update toggles with dynamic content (like trash count)
        for index in toggles.indices {
            let toggle = toggles[index]
            
            switch toggle.type {
            case .emptyTrash:
                if let service = ToggleServiceManager.shared.service(for: .emptyTrash) as? EmptyTrashService {
                    let count = await service.getTrashItemCount()
                    let title = count == 0 ? "Empty Trash (Empty)" : "Empty Trash (\(count) item\(count == 1 ? "" : "s"))"
                    
                    await MainActor.run {
                        self.toggles[index].customTitle = title
                    }
                }
            default:
                break
            }
        }
    }
}