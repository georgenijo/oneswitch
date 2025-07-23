import SwiftUI
import Combine
import os.log

@MainActor
class PreferencesViewModel: ObservableObject {
    @Published var enabledToggles: Set<ToggleType> = []
    @Published var launchAtLogin: Bool = false
    @Published var showInDock: Bool = false
    @Published var skipEmptyTrashConfirmation: Bool = false
    
    private let preferencesManager = PreferencesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Logger.preferences.info("Initializing PreferencesViewModel")
        loadPreferences()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func isToggleEnabled(_ type: ToggleType) -> Bool {
        return enabledToggles.contains(type)
    }
    
    func setToggleEnabled(_ type: ToggleType, enabled: Bool) {
        Logger.preferences.info("Setting toggle \(type.displayName) enabled: \(enabled)")
        
        if enabled {
            enabledToggles.insert(type)
        } else {
            enabledToggles.remove(type)
        }
        
        savePreferences()
    }
    
    // MARK: - Private Methods
    
    private func loadPreferences() {
        let preferences = preferencesManager.loadPreferences()
        
        self.enabledToggles = preferences.enabledToggles
        self.launchAtLogin = preferences.launchAtLogin
        self.showInDock = preferences.showInDock
        self.skipEmptyTrashConfirmation = preferences.skipEmptyTrashConfirmation
        
        Logger.preferences.debug("Loaded preferences into view model")
    }
    
    private func savePreferences() {
        // Load current preferences to preserve toggle order
        let currentPreferences = preferencesManager.loadPreferences()
        
        let preferences = UserPreferences(
            enabledToggles: enabledToggles,
            toggleOrder: currentPreferences.toggleOrder, // Preserve existing order
            launchAtLogin: launchAtLogin,
            showInDock: showInDock,
            skipEmptyTrashConfirmation: skipEmptyTrashConfirmation
        )
        
        preferencesManager.savePreferences(preferences)
        Logger.preferences.debug("Saved preferences from view model")
    }
    
    private func setupBindings() {
        // Save preferences when any property changes
        $enabledToggles
            .dropFirst() // Skip initial value
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
        
        $launchAtLogin
            .dropFirst()
            .sink { [weak self] newValue in
                self?.savePreferences()
                self?.updateLaunchAtLogin(newValue)
            }
            .store(in: &cancellables)
        
        $showInDock
            .dropFirst()
            .sink { [weak self] newValue in
                self?.savePreferences()
                self?.updateDockVisibility(newValue)
            }
            .store(in: &cancellables)
        
        $skipEmptyTrashConfirmation
            .dropFirst()
            .sink { [weak self] _ in
                self?.savePreferences()
            }
            .store(in: &cancellables)
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        // TODO: Implement launch at login using SMAppService (macOS 13+) or SMLoginItemSetEnabled
        Logger.preferences.info("Launch at login: \(enabled) - Not yet implemented")
    }
    
    private func updateDockVisibility(_ show: Bool) {
        // Update the app's dock visibility
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
        Logger.preferences.info("Dock visibility updated: \(show)")
    }
}