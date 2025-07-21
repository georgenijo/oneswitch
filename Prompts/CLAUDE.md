# QuickToggle Development Context

## Project Overview
QuickToggle is a macOS menu bar application similar to One Switch that provides quick access to system toggles and actions. Built with Swift/SwiftUI and following MVVM architecture with a services layer.

## Current Status
- **Completed Tickets**: QT-001, QT-002, QT-003, QT-004 (in review)
- **App State**: Functional with working Dark Mode toggle
- **Architecture**: MVVM + Services layer with dependency injection

## Key Architecture Decisions

### 1. Service Layer Architecture
- **ToggleServiceProtocol**: Interface for individual toggle implementations
- **SystemToggleService**: Protocol for system-wide toggle management
- **ObservableToggleService**: Base class with Combine publishers for reactive updates
- **ServiceLifecycle**: Protocol for services that need start/stop management

### 2. Dependency Injection Pattern
```swift
// Enhanced ToggleServiceManager supports runtime service registration
ToggleServiceManager.shared.register(darkModeService, for: .darkMode)
```

### 3. State Management
- ToggleViewModel manages UI state
- Services handle system integration
- Combine publishers for reactive updates
- Bidirectional sync (UI ↔ System)

## Completed Components

### QT-001: Project Setup ✅
- Swift Package Manager project structure
- Menu bar app configuration (LSUIElement)
- Comprehensive .gitignore
- Logger infrastructure
- App sandbox enabled with minimal permissions

### QT-002: Menu Bar Controller ✅
- Dynamic menu generation with MenuBuilder
- Reactive updates based on toggle states
- Light/dark mode icon support
- Keyboard shortcuts (Cmd+D for Dark Mode, etc.)
- Observer pattern with Combine

### QT-003: Toggle Model and Protocol ✅
- Comprehensive error handling (ToggleError enum)
- Mock services for development
- Service manager with lifecycle support
- Full async/await implementation
- Permission handling abstraction

### QT-004: Dark Mode Toggle ✅
- First real system integration
- NSAppleScript for Dark Mode control
- KVO observation for external changes
- Cached script compilation
- Permission handling with user guidance

## Project Structure
```
QuickToggle/
├── QuickToggleApp.swift
├── Core/
│   ├── MenuBarController.swift
│   ├── MenuBuilder.swift
│   └── Constants.swift
├── Models/
│   ├── Toggle.swift
│   ├── ToggleType.swift
│   ├── ToggleError.swift
│   └── UserPreferences.swift
├── ViewModels/
│   └── ToggleViewModel.swift
├── Services/
│   ├── Protocols/
│   │   ├── ToggleServiceProtocol.swift
│   │   ├── SystemToggleService.swift
│   │   └── ObservableToggleService.swift
│   ├── SystemToggles/
│   │   └── DarkModeService.swift
│   ├── ToggleServiceManager.swift
│   └── MockToggleService.swift
├── Utilities/
│   └── Extensions/
│       ├── Logger+App.swift
│       └── Array+Extensions.swift
└── Tests/
    └── QuickToggleTests.swift
```

## Key Code Patterns

### Service Registration (AppDelegate)
```swift
@MainActor
private func registerServices() {
    let darkModeService = DarkModeService()
    ToggleServiceManager.shared.register(darkModeService, for: .darkMode)
}
```

### Observable Service Pattern
```swift
class DarkModeService: BaseObservableToggleService {
    // Publishes state changes
    var statePublisher: AnyPublisher<Bool, Never>
    
    // Observes system appearance
    appearanceObserver = NSApp.observe(\.effectiveAppearance) { ... }
}
```

### ViewModel State Updates
```swift
// Subscribe to service state changes
observableService.statePublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] isEnabled in
        self?.updateToggleState(toggleType, isEnabled: isEnabled)
    }
```

## Testing Commands
```bash
# Build
swift build

# Run
swift run QuickToggle

# Kill existing process
pkill -f "QuickToggle"
```

## Important Technical Details

### Dark Mode Implementation
- Uses NSAppleScript with System Events
- Script: `tell application "System Events" tell appearance preferences set dark mode to [true/false]`
- Observes NSApp.effectiveAppearance for external changes
- Handles permissions gracefully

### Performance Optimizations
- AppleScript compilation cached at startup
- All operations async/await
- Efficient state observation with KVO
- Minimal menu rebuilds

### Error Handling Strategy
- ToggleError enum with localized descriptions
- Permission errors handled specially
- User guidance for resolution
- Graceful degradation

## Next Steps
1. **QT-005**: Hide Desktop Icons Toggle
2. **QT-006**: Keep Awake Implementation
3. **QT-007**: Do Not Disturb Toggle
4. **QT-010**: Preferences Window

## Known Issues/TODOs
- TODO: Add error UI (currently just logs)
- TODO: Implement remaining toggle services
- TODO: Add preferences window
- TODO: Keyboard shortcut customization

## Agent Two's Key Feedback Incorporated
1. ✅ Dependency injection in ToggleServiceManager
2. ✅ Service lifecycle management
3. ✅ State observation with Combine
4. ✅ Clean separation of concerns
5. ✅ Comprehensive error handling
6. ✅ Permission handling abstraction

## Development Guidelines
- Always use Logger instead of print
- Mock services first, real implementation second
- Test external state changes (System Preferences)
- Handle permissions gracefully
- Keep services independent and testable
- Use async/await throughout

## Bundle Identifier
`dev.quicktoggle.app`

## Minimum macOS Version
11.0 (Big Sur)

## Key Dependencies
- SwiftUI
- Combine
- AppKit (for menu bar)
- Foundation (for AppleScript)

---

This context file should be kept updated as development continues. It serves as the single source of truth for project state and architectural decisions.