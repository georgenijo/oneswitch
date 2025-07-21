# QuickToggle Project Tickets

## Epic: QuickToggle Menu Bar Application

### Sprint 1: Foundation & Core Features

---

#### QT-001: Project Setup and Basic Structure
**Type**: Task  
**Priority**: Critical  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: Done

**Description**: Create the initial Xcode project with proper structure and configuration.

**Acceptance Criteria**:
- [x] Xcode project created with menu bar app template
- [x] Project structure matches COMMON_CONTEXT.md specification
- [x] Basic Info.plist configured
- [x] .gitignore added for Xcode
- [x] Project builds and shows icon in menu bar

**Technical Notes**:
- Use macOS app template
- Set minimum deployment target to macOS 11.0
- Configure app to be agent (no dock icon)

---

#### QT-002: Menu Bar Controller Implementation
**Type**: Task  
**Priority**: Critical  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: Done

**Description**: Implement the core menu bar controller with dropdown functionality.

**Acceptance Criteria**:
- [x] MenuBarController class created
- [x] Status item appears in menu bar with icon
- [x] Dropdown menu appears on click
- [x] Supports both light and dark mode icons
- [x] Menu updates dynamically

**Dependencies**: QT-001

---

#### QT-003: Toggle Model and Protocol
**Type**: Task  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: Done

**Description**: Create the base toggle model and protocol for all system toggles.

**Acceptance Criteria**:
- [x] Toggle protocol defined with required methods
- [x] Base Toggle model created
- [x] ToggleType enum with all toggle types
- [x] ToggleService protocol for services

**Dependencies**: QT-002

---

#### QT-004: Dark Mode Toggle Implementation
**Type**: Story  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: Done

**Description**: As a user, I want to toggle between dark and light mode from the menu bar.

**Acceptance Criteria**:
- [x] Dark mode toggle appears in menu
- [x] Correctly reflects current system state
- [x] Changes system appearance when clicked
- [x] Updates immediately when changed elsewhere
- [x] Works without admin privileges

**Technical Notes**:
- Use AppleScript or System Events
- Handle permissions gracefully

**Dependencies**: QT-003

---

#### QT-005: Hide Desktop Icons Toggle
**Type**: Story  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: Done

**Description**: As a user, I want to hide/show desktop icons for clean screenshots.

**Acceptance Criteria**:
- [x] Toggle hides all desktop icons
- [x] Toggle shows icons when clicked again
- [x] State persists across app restarts
- [x] Works with multiple displays
- [x] Instant effect (with Finder restart)

**Dependencies**: QT-003

---

#### QT-006: Keep Awake Implementation
**Type**: Story  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 8  
**Status**: Done

**Description**: As a user, I want to prevent my Mac from sleeping.

**Acceptance Criteria**:
- [x] Prevents system sleep when enabled
- [x] Prevents display sleep (configurable)
- [x] Shows active state in menu
- [ ] Survives app restart (optional)
- [ ] Shows time active in tooltip

**Technical Notes**:
- Use IOPMAssertionCreateWithName
- Handle assertion properly on app quit

**Dependencies**: QT-003

---

### Sprint 2: Essential Features

---

#### QT-007: Do Not Disturb Toggle
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: Cancelled

**Description**: As a user, I want to quickly toggle Do Not Disturb mode.

**Acceptance Criteria**:
- [ ] ~~Toggles system DND mode~~
- [ ] ~~Reflects current DND state~~
- [ ] ~~Works on all supported macOS versions~~
- [ ] ~~Handles Focus modes appropriately~~

**Dependencies**: QT-003

**Cancellation Note**: This feature was cancelled after implementation due to technical limitations with modern macOS versions. The Do Not Disturb/Focus API is not publicly accessible, and the workaround using F6 key simulation was deemed unreliable.

---

#### QT-008: Screen Lock Action
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: Done

**Description**: As a user, I want to quickly lock my screen.

**Acceptance Criteria**:
- [x] Locks screen immediately when clicked
- [x] Shows as action item (not toggle)
- [x] Works with fast user switching
- [x] Has keyboard shortcut option (Cmd+L)

**Dependencies**: QT-003

**Implementation Notes**:
- Uses two methods: IOKit (primary) and AppleScript (fallback)
- No special permissions required
- Keyboard shortcut Cmd+L configured in MenuBuilder

---

#### QT-009: Empty Trash Action
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: To Do

**Description**: As a user, I want to empty trash with one click.

**Acceptance Criteria**:
- [ ] Empties trash when clicked
- [ ] Shows confirmation dialog (optional)
- [ ] Shows trash item count in menu
- [ ] Handles errors gracefully

**Dependencies**: QT-003

---

#### QT-010: Basic Preferences Window
**Type**: Story  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 8  
**Status**: To Do

**Description**: As a user, I want to customize which toggles appear in the menu.

**Acceptance Criteria**:
- [ ] SwiftUI preferences window
- [ ] List of all available toggles
- [ ] Checkboxes to show/hide toggles
- [ ] Changes reflect immediately in menu
- [ ] Preferences persist across restarts

**Dependencies**: QT-006

---

### Sprint 3: Bluetooth & Advanced Features

---

#### QT-011: Bluetooth Service Foundation
**Type**: Task  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 8  
**Status**: To Do

**Description**: Implement core Bluetooth service for device management.

**Acceptance Criteria**:
- [ ] Bluetooth service can list devices
- [ ] Can connect/disconnect devices
- [ ] Monitors connection status
- [ ] Handles permissions properly

**Dependencies**: QT-003

---

#### QT-012: AirPods Quick Connect
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: To Do

**Description**: As a user, I want to connect my AirPods with one click.

**Acceptance Criteria**:
- [ ] Shows AirPods in menu when available
- [ ] Connects with single click
- [ ] Shows connection status
- [ ] Handles multiple audio devices
- [ ] Shows battery level if available

**Dependencies**: QT-011

---

#### QT-013: Night Shift Toggle
**Type**: Story  
**Priority**: Low  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: To Do

**Description**: As a user, I want to toggle Night Shift from the menu bar.

**Acceptance Criteria**:
- [ ] Toggles Night Shift on/off
- [ ] Shows current state
- [ ] Works with scheduled Night Shift
- [ ] Available only on supported Macs

**Dependencies**: QT-003

---

### Sprint 4: Polish & Distribution

---

#### QT-014: Keyboard Shortcuts
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 8  
**Status**: To Do

**Description**: As a user, I want keyboard shortcuts for my favorite toggles.

**Acceptance Criteria**:
- [ ] Global hotkey support
- [ ] Configurable in preferences
- [ ] Visual feedback on activation
- [ ] Conflict detection
- [ ] Default shortcuts for common items

**Dependencies**: QT-010

---

#### QT-015: Launch at Login
**Type**: Story  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: To Do

**Description**: As a user, I want the app to start automatically.

**Acceptance Criteria**:
- [ ] Option in preferences
- [ ] Uses modern SMAppService API
- [ ] Works without admin privileges
- [ ] Can be toggled on/off

**Dependencies**: QT-010

---

#### QT-016: App Icon and Assets
**Type**: Task  
**Priority**: Medium  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: To Do

**Description**: Create all required icons and image assets.

**Acceptance Criteria**:
- [ ] App icon for Finder/Dock
- [ ] Menu bar icons (light/dark)
- [ ] Toggle icons for each feature
- [ ] All in @1x, @2x, @3x
- [ ] Follow Apple HIG

---

#### QT-017: Performance Optimization
**Type**: Task  
**Priority**: High  
**Assignee**: Agent One  
**Story Points**: 5  
**Status**: To Do

**Description**: Optimize app performance and memory usage.

**Acceptance Criteria**:
- [ ] App uses < 20MB RAM idle
- [ ] Menu opens instantly
- [ ] No UI lag or stuttering
- [ ] Efficient state monitoring
- [ ] Profile and fix any leaks

**Dependencies**: All features complete

---

#### QT-018: Documentation and README
**Type**: Task  
**Priority**: Low  
**Assignee**: Agent One  
**Story Points**: 3  
**Status**: To Do

**Description**: Create user and developer documentation.

**Acceptance Criteria**:
- [ ] README with features and screenshots
- [ ] Build instructions
- [ ] Architecture documentation
- [ ] Contribution guidelines
- [ ] License file

---

## Bug Tickets (To be created as found)

#### QT-BUG-001: [Template]
**Type**: Bug  
**Priority**: TBD  
**Assignee**: Agent One  
**Status**: To Do

**Description**: [Bug description]

**Steps to Reproduce**:
1. 
2. 

**Expected Behavior**:

**Actual Behavior**:

**Environment**:
- macOS Version:
- App Version:

---

## Ticket Status Guide

- **To Do**: Not started
- **In Progress**: Currently being worked on
- **In Review**: Completed by Agent One, awaiting Agent Two review
- **Changes Requested**: Agent Two requested modifications
- **Done**: Reviewed and approved by Agent Two

## How to Update Tickets

1. Agent One: Change status to "In Progress" when starting
2. Agent One: Change to "In Review" when complete
3. Agent Two: Change to "Done" or "Changes Requested" after review
4. Update checkbox items as completed
5. Add notes in channel.md referencing ticket number