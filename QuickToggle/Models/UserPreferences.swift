import Foundation

struct UserPreferences: Codable {
    var enabledToggles: Set<ToggleType>
    var toggleOrder: [ToggleType]
    var launchAtLogin: Bool
    var showInDock: Bool
    var skipEmptyTrashConfirmation: Bool
    
    static let `default` = UserPreferences(
        enabledToggles: Set([.darkMode, .desktopIcons, .keepAwake, .screenLock, .emptyTrash, .bluetooth]),
        toggleOrder: ToggleType.allCases,
        launchAtLogin: false,
        showInDock: false,
        skipEmptyTrashConfirmation: false
    )
}