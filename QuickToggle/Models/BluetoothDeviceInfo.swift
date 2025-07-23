import Foundation

struct BluetoothDeviceInfo: Identifiable, Equatable {
    let id: String // MAC address
    let name: String
    let address: String
    let isConnected: Bool
    let isPaired: Bool
    let batteryLevel: Int?
    let deviceType: DeviceType
    let lastSeenDate: Date?
    let majorDeviceClass: UInt32
    let minorDeviceClass: UInt32
    
    enum DeviceType: String, CaseIterable {
        case airPods = "AirPods"
        case keyboard = "Keyboard"
        case mouse = "Mouse"
        case trackpad = "Trackpad"
        case headphones = "Headphones"
        case speaker = "Speaker"
        case phone = "Phone"
        case computer = "Computer"
        case other = "Other"
        
        var iconName: String {
            switch self {
            case .airPods: return "airpodspro"
            case .keyboard: return "keyboard"
            case .mouse: return "computermouse"
            case .trackpad: return "trackpad"
            case .headphones: return "headphones"
            case .speaker: return "hifispeaker"
            case .phone: return "iphone"
            case .computer: return "desktopcomputer"
            case .other: return "cpu"
            }
        }
    }
    
    var displayName: String {
        // Clean up device names for better display
        if name.contains("AirPods") {
            return name
        } else if name.contains("Magic") {
            return name
        } else {
            return "\(name) (\(deviceType.rawValue))"
        }
    }
    
    var batteryIconName: String? {
        guard let level = batteryLevel else { return nil }
        
        switch level {
        case 0...25: return "battery.25"
        case 26...50: return "battery.50"
        case 51...75: return "battery.75"
        case 76...100: return "battery.100"
        default: return "battery.0"
        }
    }
    
    static func deviceType(from majorClass: UInt32, minorClass: UInt32, name: String) -> DeviceType {
        // Check name patterns first for specific devices
        let lowercaseName = name.lowercased()
        
        if lowercaseName.contains("airpod") {
            return .airPods
        } else if lowercaseName.contains("keyboard") || lowercaseName.contains("magic keyboard") {
            return .keyboard
        } else if lowercaseName.contains("mouse") || lowercaseName.contains("magic mouse") {
            return .mouse
        } else if lowercaseName.contains("trackpad") || lowercaseName.contains("magic trackpad") {
            return .trackpad
        }
        
        // Fall back to device class codes
        // Major device classes from Bluetooth spec
        switch majorClass {
        case 0x01: // Computer
            return .computer
        case 0x02: // Phone
            return .phone
        case 0x04: // Audio/Video
            // Check minor class for more specific type
            switch minorClass {
            case 0x01: return .headphones
            case 0x05: return .speaker
            default: return .headphones
            }
        case 0x05: // Peripheral (keyboard/mouse)
            // Check minor class
            switch minorClass & 0x30 {
            case 0x10: return .keyboard
            case 0x20: return .mouse
            default: return .other
            }
        default:
            return .other
        }
    }
}