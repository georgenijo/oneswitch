# QuickToggle Prompts Directory

This directory contains all prompts, documentation, and communication files for the QuickToggle project development.

## Quick Links

- [Agent One Guide](agents/agent-one.md) - Primary developer instructions
- [Agent Two Guide](agents/agent-two.md) - Code reviewer instructions
- [Current Communication](communication/channel-current.md) - Latest development updates
- [Project Overview](project/overview.md) - High-level project description
- [Technical Specification](project/technical-spec.md) - Architecture and implementation details
- [Active Tickets](project/tickets.md) - Current development tasks
- [Development Log](project/development-log.md) - Session history

## Directory Structure

```
Prompts/
├── agents/                    # Agent instructions and guidelines
│   ├── agent-one.md          # Developer guide (merged instructions + context)
│   └── agent-two.md          # Reviewer guide (merged instructions + context + quick start)
├── project/                   # Project documentation
│   ├── overview.md           # Project description and feature list
│   ├── technical-spec.md     # Technical architecture and patterns
│   ├── tickets.md            # Development task tracking
│   └── development-log.md    # Session-by-session progress log
├── communication/             # Agent communication channel
│   ├── channel-current.md    # Recent messages and updates
│   └── archive/              # Historical communication
│       └── channel-2025-01-21-session1.md
└── templates/                 # Reusable prompt templates
    └── oneswitch-clone-prompt.md
```

## File Descriptions

### Agent Files
- **agent-one.md**: Comprehensive guide for the primary developer, including role, responsibilities, current status, architecture patterns, and coding standards
- **agent-two.md**: Complete guide for the code reviewer, including review process, common issues, testing requirements, and architectural guidance

### Project Files
- **overview.md**: High-level project description, feature priority list, UI/UX guidelines, and success criteria
- **technical-spec.md**: Detailed technical architecture, service implementations, performance optimizations, and development guidelines
- **tickets.md**: Sprint planning with user stories, acceptance criteria, and task tracking
- **development-log.md**: Chronological record of development sessions and progress

### Communication Files
- **channel-current.md**: Most recent ~50-100 messages between agents, active discussions
- **archive/**: Older communication organized by session for historical reference

### Templates
- **oneswitch-clone-prompt.md**: Original project kickoff prompt

## Usage Guidelines

1. **Starting a Session**: Agents should read their respective guide files first
2. **During Development**: Update channel-current.md with progress and findings
3. **Reviewing Work**: Check current communication and relevant project files
4. **Tracking Tasks**: Update ticket status in tickets.md as work progresses
5. **Session End**: Important updates should be reflected in agent context files

## Maintenance

- Keep channel-current.md to a manageable size (~100 messages)
- Archive older messages by session when needed
- Update agent guides with important patterns or decisions
- Keep technical-spec.md current with implementation details