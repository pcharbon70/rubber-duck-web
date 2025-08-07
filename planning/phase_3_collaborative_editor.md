# Phase 3: Multi-user Collaborative Code Editor

## Overview
Implement real-time collaborative editing capabilities for human users (excluding Duck) using live_monaco_editor. This phase focuses on multi-user presence, real-time synchronization, conflict resolution, and collaborative features like shared cursors and typing indicators, similar to VS Code Live Share functionality.

## 3.1 Phoenix Presence Integration

### 3.1.1 User Presence System
```elixir
defmodule RubberduckWebWeb.Presence do
  use Phoenix.Presence,
    otp_app: :rubberduck_web,
    pubsub_server: RubberduckWeb.PubSub
    
  def track_user(session_id, user_id, metadata) do
    track(self(), "session:#{session_id}:presence", user_id, %{
      cursor_position: metadata[:cursor_position],
      selection_range: metadata[:selection_range],
      active_file: metadata[:active_file],
      typing: metadata[:typing] || false,
      color: metadata[:color],
      last_seen: DateTime.utc_now()
    })
  end
end
```
- [ ] Set up Phoenix.Presence for collaborative user tracking
- [ ] Create user presence tracking excluding Duck (LLM agent)
- [ ] Implement real-time presence updates and broadcasting
- [ ] Add user connection/disconnection handling
- [ ] Create presence state synchronization across clients
- [ ] Set up presence cleanup for disconnected users

### 3.1.2 User Color Assignment System
- [ ] Implement deterministic color assignment using hash algorithms
- [ ] Create color palette optimized for accessibility and contrast
- [ ] Ensure consistent user colors across sessions and reconnections
- [ ] Add color conflict resolution for simultaneous users
- [ ] Create user identification system with names and avatars
- [ ] Implement color customization in user preferences

### 3.1.3 Presence State Management
- [ ] Create presence state reducers for LiveView
- [ ] Implement presence diff handling for efficient updates
- [ ] Add presence state persistence for session recovery
- [ ] Create presence event broadcasting to relevant components
- [ ] Set up presence-based UI updates (user list, cursors)
- [ ] Add presence analytics and monitoring

## 3.2 Real-time Collaborative Editing

### 3.2.1 Collaborative Channel Architecture
```elixir
defmodule RubberduckWebWeb.CollaborativeEditorChannel do
  use Phoenix.Channel
  alias RubberduckWebWeb.Presence
  
  def join("session:" <> session_id <> ":editor", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket |> assign(:session_id, session_id)}
  end
  
  def handle_info(:after_join, socket) do
    Presence.track_user(socket.assigns.session_id, socket.assigns.user_id, %{
      cursor_position: {0, 0},
      selection_range: nil,
      typing: false,
      color: generate_user_color(socket.assigns.user_id)
    })
    {:noreply, socket}
  end
  
  def handle_in("editor_change", payload, socket) do
    broadcast_from(socket, "editor_change", payload)
    {:noreply, socket}
  end
  
  def handle_in("cursor_position", payload, socket) do
    Presence.update(socket, socket.assigns.user_id, %{cursor_position: payload.position})
    {:noreply, socket}
  end
end
```
- [ ] Create dedicated collaborative editor channel
- [ ] Implement operational transformation for conflict resolution
- [ ] Add real-time document synchronization
- [ ] Create change event broadcasting and handling
- [ ] Set up collaborative editing state management
- [ ] Add undo/redo functionality for collaborative context

### 3.2.2 Monaco Editor Collaborative Integration
```javascript
// LiveView Hook for collaborative Monaco integration
const CollaborativeEditorHook = {
  mounted() {
    this.editor = monaco.editor.create(this.el, {
      value: this.el.dataset.initialValue || '',
      language: this.el.dataset.language || 'javascript',
      theme: 'vs-dark'
    });

    // Track local changes and broadcast to other users
    this.editor.onDidChangeModelContent((e) => {
      this.debouncedBroadcastChanges(e.changes);
    });

    // Track cursor position and selection
    this.editor.onDidChangeCursorPosition((e) => {
      this.throttledBroadcastCursor(e.position);
    });

    // Listen for remote changes from other users
    this.handleEvent("remote_editor_change", (payload) => {
      this.applyRemoteChanges(payload);
    });

    // Listen for remote cursor positions
    this.handleEvent("remote_cursor_update", (payload) => {
      this.updateRemoteCursors(payload);
    });
  }
};
```
- [ ] Extend Monaco Editor hook for collaborative features
- [ ] Implement change tracking and broadcasting with debouncing (250ms)
- [ ] Add cursor position tracking and sharing (60fps throttling)
- [ ] Create remote change application with conflict resolution
- [ ] Set up selection range sharing and visualization
- [ ] Add collaborative editing decorations and highlights

### 3.2.3 Operational Transform Implementation
- [ ] Implement basic operational transform algorithms
- [ ] Create change operation types (insert, delete, retain)
- [ ] Add operation composition and transformation logic
- [ ] Implement vector clocks for operation ordering
- [ ] Create conflict resolution strategies
- [ ] Add operation validation and error handling

## 3.3 Live Cursors and Indicators

### 3.3.1 Real-time Cursor System
- [ ] Create cursor position broadcasting at 60fps
- [ ] Implement cursor visualization with user colors and names
- [ ] Add cursor position interpolation for smooth movement
- [ ] Create cursor hiding for inactive users
- [ ] Set up cursor position normalization across different viewport sizes
- [ ] Add cursor click and selection indicators

### 3.3.2 Typing Indicators
- [ ] Implement typing detection and broadcasting
- [ ] Create line-level typing indicators for code editing
- [ ] Add typing timeout and cleanup logic
- [ ] Set up visual typing indicators with user identification
- [ ] Create typing indicator positioning and animation
- [ ] Add typing indicator accessibility features

### 3.3.3 Selection and Highlight Sharing
- [ ] Implement selection range broadcasting
- [ ] Create visual selection highlighting for other users
- [ ] Add selection conflict handling and prioritization
- [ ] Set up selection-based collaboration features
- [ ] Create selection history and tracking
- [ ] Add selection-based commenting and annotation

## 3.4 Collaborative Features

### 3.4.1 User Awareness System
```heex
<div class="user-presence-panel">
  <div class="online-users">
    <%= for {user_id, presence} <- @presence_state do %>
      <div class="user-avatar" style={"border-color: #{presence.color}"}>
        <img src={user_avatar_url(user_id)} alt={user_name(user_id)} />
        <div class={"status-indicator #{if presence.typing, do: "typing", else: "idle"}"}>
        </div>
      </div>
    <% end %>
  </div>
  
  <div class="active-editors">
    <%= for {user_id, presence} <- users_with_active_cursors(@presence_state) do %>
      <div class="active-user" style={"background-color: #{presence.color}33"}>
        <%= user_name(user_id) %> - Line <%= presence.cursor_position.line %>
      </div>
    <% end %>
  </div>
</div>
```
- [ ] Create user presence panel with online users display
- [ ] Implement user status indicators (active, typing, away)
- [ ] Add user activity tracking and notifications
- [ ] Create user hover information and tooltips
- [ ] Set up user interaction history and analytics
- [ ] Add user preference synchronization

### 3.4.2 File and Session Management
- [ ] Implement collaborative file management
- [ ] Create file locking and access control
- [ ] Add file versioning and history tracking
- [ ] Set up session persistence and recovery
- [ ] Create session export and sharing capabilities
- [ ] Add session analytics and usage tracking

### 3.4.3 Communication Integration
- [ ] Create editor-to-chat integration for discussing code
- [ ] Add code selection sharing in chat messages
- [ ] Implement @ mentions for users in editor context
- [ ] Create collaborative code review features
- [ ] Add code commenting and annotation system
- [ ] Set up code diff discussion threads

## 3.5 Conflict Resolution and Synchronization

### 3.5.1 Document State Management
```elixir
defmodule RubberduckWeb.Editor.DocumentState do
  use GenServer
  
  defstruct [
    :session_id,
    :content,
    :version,
    :operations,
    :user_cursors,
    :pending_operations
  ]
  
  def apply_operation(document_state, operation, user_id) do
    # Apply operational transform and update document
  end
  
  def resolve_conflicts(operations) do
    # Implement conflict resolution strategy
  end
end
```
- [ ] Create document state management with GenServer
- [ ] Implement version control for collaborative documents
- [ ] Add operation history and rollback capabilities
- [ ] Create conflict detection and resolution algorithms
- [ ] Set up document state persistence and recovery
- [ ] Add document state monitoring and debugging

### 3.5.2 Network Optimization
- [ ] Implement change compaction and optimization
- [ ] Create efficient delta synchronization
- [ ] Add network partition handling and recovery
- [ ] Set up bandwidth optimization for mobile users
- [ ] Create priority-based change propagation
- [ ] Add network latency compensation

### 3.5.3 Error Recovery and Resilience
- [ ] Implement automatic conflict resolution strategies
- [ ] Create manual conflict resolution interfaces
- [ ] Add document state repair and validation
- [ ] Set up graceful degradation for network issues
- [ ] Create backup and restore functionality
- [ ] Add comprehensive error logging and monitoring

## 3.6 Mobile and Accessibility

### 3.6.1 Mobile Collaborative Editing
- [ ] Optimize touch interactions for collaborative editing
- [ ] Create mobile-specific cursor and selection handling
- [ ] Add gesture-based collaboration features
- [ ] Implement mobile keyboard optimization
- [ ] Create mobile-specific user presence indicators
- [ ] Add mobile performance optimizations

### 3.6.2 Accessibility Features
- [ ] Implement screen reader support for collaborative features
- [ ] Add keyboard navigation for user presence
- [ ] Create high contrast mode for collaborative indicators
- [ ] Set up focus management for collaborative interactions
- [ ] Add ARIA labels for collaborative elements
- [ ] Create accessible notification system for collaborative events

### 3.6.3 Performance Optimization
- [ ] Implement efficient re-rendering for presence updates
- [ ] Create cursor position throttling and batching
- [ ] Add viewport-based cursor culling
- [ ] Set up memory optimization for long collaborative sessions
- [ ] Create collaborative feature performance monitoring
- [ ] Add performance budgets and alerting

## 3.7 Testing and Quality Assurance

### 3.7.1 Collaborative Editing Tests
- [ ] Create multi-user simulation tests
- [ ] Test operational transform implementation
- [ ] Add conflict resolution scenario tests
- [ ] Create network partition and recovery tests
- [ ] Test cursor and presence synchronization
- [ ] Add performance tests for collaborative features

### 3.7.2 Real-time Communication Tests
- [ ] Test Phoenix Presence integration
- [ ] Add WebSocket message ordering tests
- [ ] Create channel communication reliability tests
- [ ] Test concurrent user scenario handling
- [ ] Add message throughput and latency tests
- [ ] Create connection failure recovery tests

### 3.7.3 UI and UX Testing
- [ ] Test collaborative UI components
- [ ] Add cursor and indicator rendering tests
- [ ] Create mobile collaboration interface tests
- [ ] Test accessibility features
- [ ] Add cross-browser compatibility tests
- [ ] Create user experience flow tests

## Dependencies and Prerequisites
- Phase 1: Core Foundation & Layout System (completed)
- Phase 2: LLM Chat System & Duck Integration (completed)  
- Monaco Editor integration with LiveView hooks
- Phoenix.Presence configured and tested
- WebSocket communication infrastructure
- Real-time conflict resolution algorithms

## Success Criteria
- [ ] Multiple users can edit code simultaneously without conflicts
- [ ] Cursor positions and selections sync in real-time across users
- [ ] Typing indicators work correctly for collaborative editing
- [ ] User presence system accurately tracks online collaborators
- [ ] Conflict resolution handles simultaneous edits gracefully
- [ ] Mobile users can participate effectively in collaborative editing
- [ ] Performance remains smooth with multiple concurrent users
- [ ] All accessibility features function correctly
- [ ] Network issues are handled gracefully with recovery
- [ ] All tests pass with comprehensive coverage

## Technical Notes
- Use operational transform or CRDT for conflict-free editing
- Throttle cursor updates to 60fps to prevent performance issues
- Implement efficient presence diffing to minimize network traffic
- Consider using WebRTC for direct peer-to-peer communication in future
- Ensure proper cleanup of collaborative state when users disconnect
- Pay special attention to mobile touch event handling

## Next Phase Dependencies
This phase provides the foundation for Phase 4 (Advanced LLM-Code Integration) by establishing:
- Real-time collaborative infrastructure
- Document state management and synchronization
- User presence and identification system
- Conflict resolution mechanisms
- Performance-optimized real-time communication