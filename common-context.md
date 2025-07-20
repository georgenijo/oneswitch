# QuickToggle - Common Project Context

## Project Overview

Building a macOS menu bar application similar to One Switch that provides quick access to system toggles and actions. The app should be lightweight, fast, and user-friendly.

## Technical Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (preferences), AppKit (menu bar)
- **Minimum macOS**: 11.0 (Big Sur)
- **Architecture**: MVVM with Services layer
- **Concurrency**: Swift async/await

## Feature Priority List

### Phase 1 - Core Features (MVP)
1. **Menu Bar Integration**
   - Status item with icon
   - Dropdown menu
   - Light/Dark mode icon support

2. **Essential Toggles**
   - Dark/Light Mode
   - Hide/Show Desktop Icons
   - Keep Awake (Caffeine alternative)
   - Do Not Disturb
   - Screen Lock

### Phase 2 - Enhanced Features
3. **Additional Toggles**
   - Empty Trash
   - Night Shift
   - AirPods/Bluetooth Audio Connection
   - Screen Saver Activation
   - True Tone (if supported)

4. **User Preferences**
   - Show/hide toggles
   - Reorder items
   - Keyboard shortcuts
   - Auto-start on login

### Phase 3 - Advanced Features
5. **Extended Functionality**
   - Low Power Mode
   - Hide Menu Bar Icons
   - WiFi/Bluetooth toggles
   - Screen Resolution switching
   - Custom shortcuts/scripts

## Project Structure

```
QuickToggle/
├── QuickToggleApp.swift
├── Info.plist
├── QuickToggle.entitlements
├── Core/
│   ├── MenuBarController.swift
│   ├── AppDelegate.swift
│   └── Constants.swift
├── Models/
│   ├── Toggle.swift
│   ├── ToggleType.swift
│   └── UserPreferences.swift
├── ViewModels/
│   ├── ToggleViewModel.swift
│   └── PreferencesViewModel.swift
├── Views/
│   ├── MenuView.swift
│   ├── PreferencesWindow.swift
│   └── Components/
├── Services/
│   ├── Protocols/
│   │   └── ToggleServiceProtocol.swift
│   ├── SystemToggles/
│   │   ├── DarkModeService.swift
│   │   ├── DesktopIconsService.swift
│   │   ├── KeepAwakeService.swift
│   │   └── ...
│   ├── BluetoothService.swift
│   ├── ShortcutService.swift
│   └── PreferencesService.swift
├── Utilities/
│   ├── Extensions/
│   ├── Helpers/
│   └── KeyboardShortcuts.swift
├── Resources/
│   └── Assets.xcassets
└── Tests/
```

## Key Technical Decisions

### Menu Bar Implementation
- Use `NSStatusBar` and `NSStatusItem` for menu bar presence
- `NSMenu` for dropdown (not SwiftUI) for better control
- Dynamic menu building based on user preferences

### State Management
- Each toggle service manages its own state
- Central `ToggleViewModel` coordinates services
- UserDefaults for preference persistence
- Combine/NotificationCenter for state updates

### Permissions Strategy
- Request only when needed (lazy permissions)
- Clear explanations in alerts
- Graceful degradation if denied
- Check capabilities before showing toggles

### Performance Guidelines
- Lazy initialization of services
- Minimal work in menu bar click handler
- Background queue for system operations
- Efficient observers for system changes

## Code Standards

### Swift Style
- Use Swift API design guidelines
- Prefer value types where appropriate
- Use `async/await` for asynchronous operations
- Comprehensive error handling with `Result` type

### Documentation
- Document all public APIs
- Explain complex logic inline
- README with setup instructions
- Comments for non-obvious decisions

### Testing
- Unit tests for services
- UI tests for critical paths
- Manual test checklist
- Performance profiling

## Security & Privacy

### Entitlements Needed
- `com.apple.security.automation.apple-events` (for AppleScript)
- Bluetooth access
- Accessibility (for some features)

### Privacy Considerations
- No analytics or tracking
- No network requests except for updates
- Local storage only
- Clear privacy policy

## UI/UX Guidelines

### Menu Design
- Clean, minimal interface
- Clear toggle states (checkmarks)
- Logical grouping with separators
- Keyboard navigation support

### Preferences Window
- SwiftUI-based
- Searchable toggle list
- Drag-and-drop reordering
- Live preview of changes

### Icons
- SF Symbols where possible
- Custom icons follow Apple HIG
- Support for Light/Dark modes
- @2x and @3x versions

## Development Workflow

1. **Agent One** implements features
2. **Agent Two** reviews and suggests improvements
3. Both update `channel.md` with progress
4. Iterate until feature is complete
5. Move to next priority item

## Success Criteria

- App launches in < 1 second
- Uses < 20MB RAM when idle
- All toggles work reliably
- Smooth, native feel
- No crashes or hangs
- Easy to use without documentation

## Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Menu Bar App Best Practices](https://developer.apple.com/design/human-interface-guidelines/macos/menus/menu-bar-menus/)

## Questions to Resolve Early

1. App name (QuickToggle vs other options)
2. Distribution method (direct, App Store, or both)
3. Update mechanism
4. Icon design style
5. Monetization (if any)