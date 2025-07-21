import Foundation

struct Toggle: Identifiable {
    var id: String { type.rawValue }
    let type: ToggleType
    var customTitle: String?
    var title: String { customTitle ?? type.displayName }
    var iconName: String { type.iconName }
    var isEnabled: Bool
    var isAvailable: Bool
    
    init(type: ToggleType, isEnabled: Bool = false, isAvailable: Bool = true, customTitle: String? = nil) {
        self.type = type
        self.isEnabled = isEnabled
        self.isAvailable = isAvailable
        self.customTitle = customTitle
    }
}