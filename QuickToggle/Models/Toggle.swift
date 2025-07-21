import Foundation

struct Toggle: Identifiable {
    var id: String { type.rawValue }
    let type: ToggleType
    var title: String { type.displayName }
    var iconName: String { type.iconName }
    var isEnabled: Bool
    var isAvailable: Bool
    
    init(type: ToggleType, isEnabled: Bool = false, isAvailable: Bool = true) {
        self.type = type
        self.isEnabled = isEnabled
        self.isAvailable = isAvailable
    }
}