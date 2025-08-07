# Phase 1: Core Foundation & Layout System

## Overview
Establish the foundational infrastructure for a hybrid collaborative coding platform that combines LLM chat assistance (user ↔ Duck) with multi-user collaborative code editing. This phase focuses on the core layout system, basic LiveView architecture, and essential websocket communication setup.

## 1.1 LiveView Architecture Foundation

### 1.1.1 Main Collaborative LiveView Component
- [ ] Create `CollaborativeCodingLive` as the primary LiveView module
- [ ] Implement basic mount/3 function with session management
- [ ] Set up socket assigns for user identification and session state
- [ ] Create basic template structure for editor/chat split layout
- [ ] Implement user authentication and session persistence
- [ ] Add basic error handling and connection recovery

### 1.1.2 Component Architecture Setup  
- [ ] Create `EditorComponent` LiveView component for Monaco integration
- [ ] Create `ChatComponent` LiveView component for LLM interaction
- [ ] Create `UserPresenceComponent` for collaborative user tracking
- [ ] Set up component communication patterns using send_update/3
- [ ] Implement component-specific socket assigns and state management
- [ ] Add component lifecycle management (mount, update, terminate)

### 1.1.3 Session and User Management
- [ ] Integrate with existing Ash authentication system
- [ ] Create user session tracking with unique session IDs
- [ ] Implement "Duck" LLM agent representation in session
- [ ] Set up user role differentiation (human vs. LLM agent)
- [ ] Create session persistence across reconnections
- [ ] Add session cleanup and timeout handling

## 1.2 Responsive Layout System

### 1.2.1 Core Layout Structure
- [ ] Implement 70/30 split ratio (editor/chat) as default
- [ ] Create CSS Grid-based layout with Tailwind CSS
- [ ] Add minimum width constraints (280px chat, 400px editor)
- [ ] Implement layout state persistence in browser localStorage
- [ ] Create layout configuration options in user preferences
- [ ] Add visual indicators for panel boundaries

### 1.2.2 Resizable Panel System
- [ ] Create resizable panel component with drag handles
- [ ] Implement 4px draggable border with 10px hover expansion
- [ ] Add double-click reset to default 70/30 ratio functionality
- [ ] Create smooth resize animations and transitions
- [ ] Implement resize constraints and validation
- [ ] Add keyboard accessibility for panel resizing

### 1.2.3 Mobile-Responsive Design
- [ ] Implement mobile-first responsive breakpoints
- [ ] Create stacked layout for screens < 768px
- [ ] Add collapsible chat panel for mobile devices
- [ ] Implement swipe gesture support for panel switching
- [ ] Create floating action buttons for mobile navigation
- [ ] Ensure 44px minimum touch targets for mobile

## 1.3 Live Monaco Editor Integration

### 1.3.1 JavaScript Hook Setup
- [ ] Install and configure live_monaco_editor assets
- [ ] Create MonacoEditorHook in app.js with proper initialization
- [ ] Import live_monaco_editor CSS into app.css
- [ ] Set up Monaco Editor with Elixir syntax highlighting
- [ ] Configure editor theme and basic options
- [ ] Add editor instance management for multiple sessions

### 1.3.2 LiveView-Monaco Integration
- [ ] Create editor component with phx-update="ignore"
- [ ] Implement bidirectional data flow (LiveView ↔ Monaco)
- [ ] Set up editor change event handling with debouncing (250ms)
- [ ] Create editor value synchronization system
- [ ] Add editor state persistence and recovery
- [ ] Implement editor validation and error display

### 1.3.3 Editor Configuration and Options
- [ ] Configure Monaco Editor with comprehensive language support
- [ ] Set up theme switching (light/dark) capability
- [ ] Configure editor settings (font size, line numbers, etc.)
- [ ] Add custom keybindings for collaborative features
- [ ] Implement editor focus management
- [ ] Create editor accessibility enhancements

## 1.4 Phoenix Channels Foundation

### 1.4.1 Channel Architecture Setup
- [ ] Create base `CollaborativeChannel` module
- [ ] Set up channel routing in endpoint.ex
- [ ] Implement channel authentication and authorization
- [ ] Create topic hierarchy for different communication types
- [ ] Add channel connection lifecycle management
- [ ] Set up channel error handling and logging

### 1.4.2 WebSocket Communication Patterns
- [ ] Design message format standards for different event types
- [ ] Implement message serialization and deserialization
- [ ] Create channel message rate limiting and throttling
- [ ] Add message acknowledgment and delivery confirmation
- [ ] Set up websocket reconnection logic with exponential backoff
- [ ] Create websocket connection monitoring and health checks

### 1.4.3 Channel Topic Organization
```elixir
# Planned topic structure:
"session:#{session_id}:llm_chat"        # User ↔ Duck communication
"session:#{session_id}:editor"          # Multi-user editor collaboration  
"session:#{session_id}:presence"        # User presence tracking
"session:#{session_id}:system"          # System notifications
```
- [ ] Create topic naming conventions and validation
- [ ] Implement topic-based message routing
- [ ] Add topic subscription and unsubscription management
- [ ] Create topic-specific authorization rules
- [ ] Set up topic cleanup and garbage collection

## 1.5 Basic UI Components

### 1.5.1 Core Interface Components
- [ ] Create responsive header with user info and session status
- [ ] Implement loading states and connection indicators
- [ ] Add error boundaries and fallback UI components
- [ ] Create toast notification system for user feedback
- [ ] Implement modal system for settings and preferences
- [ ] Add basic accessibility features (ARIA labels, focus management)

### 1.5.2 User Interface Polish
- [ ] Implement consistent color scheme and typography
- [ ] Add hover states and interactive feedback
- [ ] Create smooth transitions and micro-animations
- [ ] Implement dark/light theme support
- [ ] Add user preference persistence
- [ ] Create consistent spacing and layout standards

## 1.6 Testing Infrastructure

### 1.6.1 LiveView Component Tests
- [ ] Set up test fixtures for user sessions and authentication
- [ ] Create tests for CollaborativeCodingLive mount and lifecycle
- [ ] Test component communication and state management
- [ ] Add tests for layout responsiveness and panel resizing
- [ ] Create integration tests for Monaco Editor integration
- [ ] Set up visual regression testing for UI components

### 1.6.2 Channel Communication Tests
- [ ] Create test cases for channel connection and authentication
- [ ] Test websocket message handling and routing
- [ ] Add tests for channel topic organization and security
- [ ] Create performance tests for message throughput
- [ ] Test connection recovery and error handling
- [ ] Add integration tests for LiveView-Channel interaction

## Dependencies and Prerequisites
- Existing Ash authentication system
- Phoenix LiveView 1.1+ with WebSocket support  
- Live Monaco Editor library (installed)
- Tailwind CSS for responsive design
- Phoenix Channels for websocket communication

## Success Criteria
- [ ] Responsive layout functions correctly on all device sizes
- [ ] Monaco Editor integrates seamlessly with LiveView
- [ ] Phoenix Channels handle websocket communication reliably
- [ ] User authentication and session management work properly
- [ ] Basic UI components provide good user experience
- [ ] All tests pass and provide good coverage
- [ ] Layout resizing works smoothly with proper constraints
- [ ] WebSocket reconnection and error recovery function correctly

## Technical Notes
- Use `phx-update="ignore"` for Monaco Editor to prevent LiveView interference
- Implement optimistic updates where possible to improve perceived performance
- Consider using temporary assigns for ephemeral UI state
- Ensure proper cleanup of WebSocket connections and editor instances
- Pay special attention to mobile touch events and gesture handling

## Next Phase Dependencies
This phase provides the foundation for Phase 2 (LLM Chat System) by establishing:
- Reliable websocket communication via Phoenix Channels
- User session and authentication management  
- Basic UI layout and responsive design
- Monaco Editor integration for code editing
- Component architecture for future collaborative features