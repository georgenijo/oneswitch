import Foundation
import os.log

class PreferencesManager {
    static let shared = PreferencesManager()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        Logger.preferences.info("PreferencesManager initialized")
        migratePreferencesIfNeeded()
    }
    
    // MARK: - Public Methods
    
    func loadPreferences() -> UserPreferences {
        Logger.preferences.debug("Loading preferences from UserDefaults")
        
        // Load enabled toggles
        var enabledToggles: Set<ToggleType> = []
        if let savedToggleStrings = userDefaults.array(forKey: Constants.UserDefaults.enabledTogglesKey) as? [String] {
            enabledToggles = Set(savedToggleStrings.compactMap { ToggleType(rawValue: $0) })
        } else {
            // Use default if not set
            enabledToggles = UserPreferences.default.enabledToggles
        }
        
        // Load toggle order
        var toggleOrder: [ToggleType] = []
        if let savedOrderStrings = userDefaults.array(forKey: Constants.UserDefaults.toggleOrderKey) as? [String] {
            toggleOrder = savedOrderStrings.compactMap { ToggleType(rawValue: $0) }
        } else {
            // Use default order
            toggleOrder = UserPreferences.default.toggleOrder
        }
        
        // Load other preferences
        let launchAtLogin = userDefaults.object(forKey: Constants.UserDefaults.launchAtLoginKey) as? Bool ?? UserPreferences.default.launchAtLogin
        let showInDock = userDefaults.object(forKey: "showInDock") as? Bool ?? UserPreferences.default.showInDock
        let skipEmptyTrashConfirmation = userDefaults.object(forKey: "skipEmptyTrashConfirmation") as? Bool ?? false
        
        let preferences = UserPreferences(
            enabledToggles: enabledToggles,
            toggleOrder: toggleOrder,
            launchAtLogin: launchAtLogin,
            showInDock: showInDock,
            skipEmptyTrashConfirmation: skipEmptyTrashConfirmation
        )
        
        Logger.preferences.info("Loaded preferences with \(enabledToggles.count) enabled toggles")
        return preferences
    }
    
    func savePreferences(_ preferences: UserPreferences) {
        Logger.preferences.info("Saving preferences to UserDefaults")
        
        // Save enabled toggles
        let toggleStrings = preferences.enabledToggles.map { $0.rawValue }
        userDefaults.set(toggleStrings, forKey: Constants.UserDefaults.enabledTogglesKey)
        
        // Save toggle order
        let orderStrings = preferences.toggleOrder.map { $0.rawValue }
        userDefaults.set(orderStrings, forKey: Constants.UserDefaults.toggleOrderKey)
        
        // Save other preferences
        userDefaults.set(preferences.launchAtLogin, forKey: Constants.UserDefaults.launchAtLoginKey)
        userDefaults.set(preferences.showInDock, forKey: "showInDock")
        userDefaults.set(preferences.skipEmptyTrashConfirmation, forKey: "skipEmptyTrashConfirmation")
        
        // Post notification
        NotificationCenter.default.post(name: Constants.Notifications.preferencesChanged, object: nil)
        
        Logger.preferences.debug("Preferences saved and notification posted")
    }
    
    func isToggleEnabled(_ type: ToggleType) -> Bool {
        let preferences = loadPreferences()
        return preferences.enabledToggles.contains(type)
    }
    
    func setToggleEnabled(_ type: ToggleType, enabled: Bool) {
        var preferences = loadPreferences()
        
        if enabled {
            preferences.enabledToggles.insert(type)
        } else {
            preferences.enabledToggles.remove(type)
        }
        
        savePreferences(preferences)
        Logger.preferences.info("Toggle \(type.displayName) enabled: \(enabled)")
    }
    
    // MARK: - Private Methods
    
    private func migratePreferencesIfNeeded() {
        // Check if this is first launch
        let hasLaunchedBefore = userDefaults.bool(forKey: Constants.UserDefaults.firstLaunchKey)
        
        if !hasLaunchedBefore {
            Logger.preferences.info("First launch detected, setting default preferences")
            
            // Save default preferences
            savePreferences(UserPreferences.default)
            
            // Mark as launched
            userDefaults.set(true, forKey: Constants.UserDefaults.firstLaunchKey)
        } else {
            // Handle any necessary migrations here
            Logger.preferences.debug("Not first launch, checking for migrations")
        }
    }
}