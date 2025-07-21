# One Switch Clone - Mac Menu Bar App Development Prompt

## System Prompt

You are an expert macOS developer specializing in Swift, SwiftUI, and AppKit development. You have deep knowledge of:
- macOS system APIs and frameworks
- Menu bar (status bar) application development
- System permissions and entitlements
- macOS security and sandboxing
- Bluetooth framework integration
- User defaults and preferences management
- Keyboard shortcuts and global hotkeys
- macOS appearance and theming
- Performance optimization for background apps
- Modern Swift concurrency (async/await)
- Accessibility features

You write clean, well-documented, production-ready code following Apple's Human Interface Guidelines and best practices. You prioritize user experience, performance, and reliability.

## Main Development Prompt

Build a macOS menu bar application called "QuickToggle" (or your preferred name) that provides quick access to common system toggles and actions. The app should be similar to One Switch, sitting in the menu bar and offering a dropdown with various system controls.

### Core Requirements:

#### 1. **Menu Bar Integration**
- Create a status bar item with a customizable icon
- Support both Light and Dark mode icons
- Dropdown menu when clicked
- Minimal memory footprint when running

#### 2. **Essential Toggle Features** (implement these first):
- **Hide/Show Desktop Icons**: Toggle visibility of all desktop items
- **Dark/Light Mode**: Switch between macOS appearance modes
- **Keep Awake**: Prevent Mac from sleeping (like Caffeine/Amphetamine)
- **Do Not Disturb**: Toggle system DND mode
- **Screen Lock**: Quick lock screen action
- **Empty Trash**: One-click trash emptying
- **AirPods Connection**: Quick connect/disconnect Bluetooth audio devices

#### 3. **Additional Features** (implement after core features):
- **Night Shift**: Toggle blue light filter
- **True Tone**: Toggle True Tone display (if supported)
- **Screen Saver**: Activate screen saver immediately
- **Low Power Mode**: Toggle system low power mode
- **Hide Menu Bar Icons**: Hide other menu bar items
- **Bluetooth**: Quick Bluetooth on/off
- **WiFi**: Toggle WiFi connection
- **Screen Resolution**: Quick resolution switching

#### 4. **User Customization**
- Preferences window to:
  - Show/hide individual toggles
  - Reorder toggle items
  - Set keyboard shortcuts for each action
  - Configure auto-start on login
  - Choose menu bar icon style
- Ability to add custom shortcuts/scripts

#### 5. **Technical Implementation Details**

**Project Structure**:
```
QuickToggle/
├── QuickToggleApp.swift (main app entry)
├── MenuBarController.swift (status bar management)
├── Models/
│   ├── Toggle.swift (toggle data model)
│   └── ToggleType.swift (enum for toggle types)
├── ViewModels/
│   └── ToggleViewModel.swift
├── Views/
│   ├── MenuView.swift (dropdown menu UI)
│   └── PreferencesView.swift
├── Services/
│   ├── SystemToggleService.swift (system API calls)
│   ├── BluetoothService.swift
│   └── ShortcutService.swift
├── Utilities/
│   ├── KeyboardShortcuts.swift
│   └── UserDefaultsManager.swift
└── Resources/
    └── Assets.xcassets
```

**Key Technologies to Use**:
- SwiftUI for preferences window
- AppKit for menu bar integration
- IOBluetooth for Bluetooth functionality
- Core Graphics for desktop/display manipulation
- System Configuration framework
- Accessibility framework (with proper permissions)

**Implementation Guidelines**:
1. Start with a basic menu bar app that displays a dropdown
2. Implement one toggle at a time, starting with simpler ones (Dark Mode)
3. Use proper error handling and fallbacks
4. Request necessary permissions (Accessibility, Bluetooth, etc.)
5. Implement state persistence using UserDefaults
6. Add keyboard shortcut support using NSEvent monitoring
7. Ensure the app works on macOS 11.0+ (Big Sur and later)

**Code Quality Requirements**:
- Use MVVM architecture
- Implement proper separation of concerns
- Add comprehensive error handling
- Include inline documentation
- Use Swift's modern concurrency features
- Follow Swift naming conventions
- Implement unit tests for core functionality

**Performance Considerations**:
- Lazy load features that aren't immediately needed
- Minimize menu bar redraw operations
- Use efficient observers for system state changes
- Implement debouncing for rapid toggle actions

**Security & Privacy**:
- Request minimal permissions
- Clearly explain why each permission is needed
- Store no user data beyond preferences
- Sign the app with Developer ID
- Consider notarization for distribution

### Example Implementation Snippet:

```swift
// Example: Dark Mode Toggle Implementation
@MainActor
class DarkModeToggle: SystemToggle {
    override var title: String { "Dark Mode" }
    override var icon: NSImage? { NSImage(systemSymbolName: "moon.fill", accessibilityDescription: nil) }
    
    override var isOn: Bool {
        get { 
            UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" 
        }
        set {
            Task {
                let script = """
                tell application "System Events"
                    tell appearance preferences
                        set dark mode to \(newValue)
                    end tell
                end tell
                """
                
                try await runAppleScript(script)
            }
        }
    }
}
```

### Deliverables:
1. Complete Xcode project with all core features
2. App icon and menu bar icons
3. Basic documentation/README
4. Build instructions
5. Code comments explaining complex implementations

Start by Breaking everything into a task list and then writing that into a new file called task list.MD