import Foundation

enum ToggleType: String, CaseIterable, Codable {
    case darkMode = "darkMode"
    case desktopIcons = "desktopIcons"
    case keepAwake = "keepAwake"
    case screenLock = "screenLock"
    case emptyTrash = "emptyTrash"
    case nightShift = "nightShift"
    case airPods = "airPods"
    case screenSaver = "screenSaver"
    case trueTone = "trueTone"
    case lowPowerMode = "lowPowerMode"
    case hideMenuBarIcons = "hideMenuBarIcons"
    case wifi = "wifi"
    case bluetooth = "bluetooth"
    
    var displayName: String {
        switch self {
        case .darkMode: return "Dark Mode"
        case .desktopIcons: return "Desktop Icons"
        case .keepAwake: return "Keep Awake"
        case .screenLock: return "Lock Screen"
        case .emptyTrash: return "Empty Trash"
        case .nightShift: return "Night Shift"
        case .airPods: return "AirPods"
        case .screenSaver: return "Screen Saver"
        case .trueTone: return "True Tone"
        case .lowPowerMode: return "Low Power Mode"
        case .hideMenuBarIcons: return "Hide Menu Bar Icons"
        case .wifi: return "Wi-Fi"
        case .bluetooth: return "Bluetooth"
        }
    }
    
    var iconName: String {
        switch self {
        case .darkMode: return "moon.circle"
        case .desktopIcons: return "menubar.rectangle"
        case .keepAwake: return "cup.and.saucer"
        case .screenLock: return "lock"
        case .emptyTrash: return "trash"
        case .nightShift: return "sunset"
        case .airPods: return "airpodspro"
        case .screenSaver: return "tv"
        case .trueTone: return "sun.max"
        case .lowPowerMode: return "battery.25"
        case .hideMenuBarIcons: return "menubar.dock.rectangle"
        case .wifi: return "wifi"
        case .bluetooth: return "bluetooth"
        }
    }
    
    var isAction: Bool {
        switch self {
        case .screenLock, .emptyTrash, .screenSaver:
            return true
        default:
            return false
        }
    }
}