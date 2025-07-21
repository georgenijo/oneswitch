# QuickToggle Technical Specification

## Architecture Overview

QuickToggle is built using MVVM architecture with a services layer for system integration.

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

## Implementation Patterns

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

## Technical Details

### Bundle Identifier
`dev.quicktoggle.app`

### Minimum macOS Version
11.0 (Big Sur)

### Key Dependencies
- SwiftUI
- Combine
- AppKit (for menu bar)
- Foundation (for AppleScript)

### Testing Commands
```bash
# Build
swift build

# Run
swift run QuickToggle

# Kill existing process
pkill -f "QuickToggle"
```

## Service Implementations

### Dark Mode
- Uses NSAppleScript with System Events
- Script: `tell application "System Events" tell appearance preferences set dark mode to [true/false]`
- Observes NSApp.effectiveAppearance for external changes
- Handles permissions gracefully

### Desktop Icons
- Uses `defaults` command for `com.apple.finder CreateDesktop`
- Requires Finder restart
- Background polling for state changes

### Keep Awake
- IOPMAssertion API (no polling)
- Direct state management via assertion ID
- Battery-efficient design

### Screen Lock
- Primary: IOKit login framework
- Fallback: AppleScript Ctrl+Cmd+Q
- No permissions required

### Empty Trash
- Primary: AppleScript with Finder
- Fallback: FileManager iteration
- Dynamic count with caching
- Automation permission handling

## Performance Optimizations
- AppleScript compilation cached at startup
- All operations async/await
- Efficient state observation with KVO
- Minimal menu rebuilds
- Background threads for heavy operations

## Error Handling Strategy
- ToggleError enum with localized descriptions
- Permission errors handled specially
- User guidance for resolution
- Graceful degradation

## Security Considerations
- App Sandbox enabled
- Minimal entitlements requested
- Automation permissions only when needed
- No network access required

## Development Guidelines
- Always use Logger instead of print
- Mock services first, real implementation second
- Test external state changes (System Preferences)
- Handle permissions gracefully
- Keep services independent and testable
- Use async/await throughout