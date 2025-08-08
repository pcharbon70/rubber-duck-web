# Phase 2: LLM Chat System & Duck Integration

**STATUS: ~15% STARTED** 🚧

## Important Architecture Note
**The Duck LLM backend server is an external service that already exists.** This project implements the web client that connects to it via WebSockets. All references to "server" in this document refer to client-side handling unless explicitly noted as the external Duck server.

## Completion Summary
- ✅ **Duck Client Representation**: Duck visual identity created (SVG component)
- ✅ **Basic Chat UI**: Chat component with message display implemented
- ✅ **Channel Structure**: Basic channel topics for browser-to-Phoenix communication
- ⚠️ **Pending**: WebSocket client to LLM server, conversation state, streaming responses

## Overview
Implement the web client for the LLM chat system, enabling users to communicate with the external "Duck" server (the coding assistant backend) via Phoenix Channels as a WebSocket client. This phase establishes client-side conversation management, streaming response handling, and chat UI optimized for LLM interactions, similar to claude.ai but integrated with the collaborative coding environment.

## 2.1 Duck LLM Client Integration

### 2.1.1 Duck Client Representation
- [ ] Create `Duck` module as LLM agent representation
- [ ] Implement Duck user session with special agent privileges
- [ ] Create Duck avatar, branding, and visual identity
- [ ] Set up Duck agent capabilities and limitations definition
- [ ] Add Duck session persistence across server restarts
- [ ] Implement Duck agent health monitoring and fallback

### 2.1.2 LLM Server WebSocket Client
- [ ] Create `LLMChannelClient` as WebSocket client to connect to external Duck server
- [ ] Implement WebSocket client connection to existing LLM server endpoint
- [ ] Set up client authentication and API key management for server access
- [ ] Create client-side message serialization/deserialization for server protocol
- [ ] Add client connection monitoring and automatic reconnection logic
- [ ] Implement client-side rate limiting and request queuing

### 2.1.3 Server Response Processing (Client-side)
- [ ] Create client-side streaming response handler for server messages
- [ ] Implement client-side message chunking and progressive rendering
- [ ] Add client validation and error handling for server responses
- [ ] Create client formatting for different server response types
- [ ] Set up client-side response caching for repeated queries
- [ ] Add client timeout and fallback handling for server unavailability

## 2.2 Conversation Management System

### 2.2.1 Conversation Domain Model
```elixir
# Ash Resource: Conversation
defmodule RubberduckWeb.Conversations.Conversation do
  use Ash.Resource, 
    data_layer: Ash.DataLayer.Ets  # Or preferred persistence

  attributes do
    uuid_primary_key :id
    attribute :session_id, :string, allow_nil?: false
    attribute :user_id, :string, allow_nil?: false  
    attribute :title, :string
    attribute :context_window, :map, default: %{}
    attribute :status, :atom, constraints: [one_of: [:active, :archived, :error]]
    timestamps()
  end
end
```
- [ ] Create Conversation Ash resource with unique conversation IDs
- [ ] Implement conversation creation and lifecycle management
- [ ] Add conversation metadata (title, creation time, participants)
- [ ] Create conversation archival and cleanup system
- [ ] Set up conversation access control and permissions
- [ ] Add conversation search and filtering capabilities

### 2.2.2 Message Domain Model
```elixir
# Ash Resource: Message
defmodule RubberduckWeb.Conversations.Message do
  use Ash.Resource

  attributes do
    uuid_primary_key :id
    attribute :conversation_id, :string, allow_nil?: false
    attribute :sender_type, :atom, constraints: [one_of: [:user, :duck]]
    attribute :sender_id, :string, allow_nil?: false
    attribute :content, :string, allow_nil?: false
    attribute :message_type, :atom, constraints: [one_of: [:text, :code, :system]]
    attribute :metadata, :map, default: %{}
    attribute :streaming_complete, :boolean, default: false
    timestamps()
  end
end
```
- [ ] Create Message Ash resource for conversation history
- [ ] Implement message threading and reply functionality
- [ ] Add message content type handling (text, code blocks, system)
- [ ] Create message validation and sanitization
- [ ] Set up message pagination and lazy loading
- [ ] Add message search and filtering within conversations

### 2.2.3 Context Management
- [ ] Implement sliding window context management (2048 tokens)
- [ ] Create context summarization for long conversations
- [ ] Add file reference persistence in conversation context
- [ ] Implement context relevance scoring and pruning
- [ ] Create conversation branching for exploring alternatives
- [ ] Add context export and import functionality

## 2.3 Phoenix Channel LLM Integration

### 2.3.1 LLM Chat Channel (Client-side)
```elixir
defmodule RubberduckWebWeb.LLMChatChannel do
  use Phoenix.Channel
  
  def join("session:" <> session_id <> ":llm_chat", _payload, socket) do
    # Channel join logic with conversation setup
    # Connect to external Duck LLM server via WebSocket client
  end
  
  def handle_in("new_message", %{"content" => content}, socket) do
    # Forward user message to external Duck server
  end
  
  def handle_info({:server_response_chunk, chunk}, socket) do
    # Stream Duck server response chunks to browser client
  end
end
```
- [x] Create dedicated LLM chat channel for browser ↔ Phoenix server communication
- [x] Implement channel join with conversation initialization
- [ ] Add WebSocket client connection to external Duck LLM server
- [ ] Forward messages between browser and LLM server
- [ ] Handle streaming responses from LLM server to browser
- [ ] Set up authentication pass-through to LLM server
- [ ] Add connection error handling and recovery for both connections

### 2.3.2 Streaming Response System (Client Implementation)
- [ ] Handle streaming responses from external LLM server
- [ ] Forward streaming chunks to browser via Phoenix Channels
- [ ] Create progressive message rendering in chat UI
- [ ] Display typing indicators while LLM server is processing
- [ ] Implement request cancellation to LLM server
- [ ] Create client-side buffering for optimal UI updates
- [ ] Handle response completion signals from LLM server

### 2.3.3 Channel Message Patterns
```elixir
# Message patterns for different event types:
%{event: "user_message", payload: %{content: "...", conversation_id: "..."}}
%{event: "duck_typing", payload: %{conversation_id: "..."}}
%{event: "duck_response_start", payload: %{message_id: "...", conversation_id: "..."}}
%{event: "duck_response_chunk", payload: %{chunk: "...", message_id: "..."}}
%{event: "duck_response_complete", payload: %{message_id: "...", final_content: "..."}}
```
- [ ] Define comprehensive message event patterns
- [ ] Implement message acknowledgment and delivery confirmation
- [ ] Add message ordering and sequence handling
- [ ] Create message retry logic for failed deliveries
- [ ] Set up message compression for large responses
- [ ] Add message encryption for sensitive content

## 2.4 LLM-Optimized Chat UI

### 2.4.1 Conversation Interface Design
- [ ] Create claude.ai-inspired conversation layout
- [ ] Implement message bubbles with user/Duck differentiation
- [ ] Add progressive message rendering for streaming responses
- [ ] Create conversation history with infinite scroll
- [ ] Implement conversation search and filtering UI
- [ ] Add conversation management (new, archive, delete)

### 2.4.2 Message Content Rendering
- [ ] Implement syntax highlighting for code blocks using Prism.js
- [ ] Add support for markdown rendering in Duck responses
- [ ] Create collapsible code blocks for better readability
- [ ] Implement copy-to-clipboard for code snippets
- [ ] Add message timestamps and read receipts
- [ ] Create message actions (copy, delete, react)

### 2.4.3 Code Block Integration
```heex
<div class="message-content">
  <%= if @message.content_type == :code do %>
    <div class="code-block-container">
      <pre class="bg-gray-900 rounded-lg p-4 overflow-x-auto">
        <code class={"language-#{@message.metadata.language} text-sm"}>
          <%= @message.content %>
        </code>
      </pre>
      <div class="code-actions flex gap-2 mt-2">
        <button phx-click="copy_code" phx-value-message-id={@message.id}>
          Copy
        </button>
        <button phx-click="apply_to_editor" phx-value-message-id={@message.id}>
          Apply to Editor
        </button>
        <button phx-click="insert_at_cursor" phx-value-message-id={@message.id}>
          Insert at Cursor
        </button>
      </div>
    </div>
  <% else %>
    <div class="prose prose-sm dark:prose-invert">
      <%= raw(markdown_to_html(@message.content)) %>
    </div>
  <% end %>
</div>
```
- [ ] Create code block components with action buttons
- [ ] Implement code syntax detection and highlighting
- [ ] Add code diff visualization for suggestions
- [ ] Create code block folding and expansion
- [ ] Set up code validation before applying to editor
- [ ] Add code block versioning and comparison

### 2.4.4 Input and Interaction
- [ ] Create multi-line input with auto-resize capability
- [ ] Implement @ symbol mentions for file references
- [ ] Add command palette for quick actions
- [ ] Create keyboard shortcuts for common operations
- [ ] Implement drag-and-drop for file uploads
- [ ] Add voice input capability (future consideration)

## 2.5 Real-time Communication

### 2.5.1 WebSocket Message Handling
- [ ] Implement efficient message serialization (JSON/MessagePack)
- [ ] Create message compression for large Duck responses
- [ ] Add message batching for performance optimization
- [ ] Implement message acknowledgment and retry logic
- [ ] Create connection heartbeat and health monitoring
- [ ] Add graceful degradation for network issues

### 2.5.2 Connection Management
- [ ] Implement automatic reconnection with exponential backoff
- [ ] Create connection state persistence across reconnects
- [ ] Add offline message queuing and sync
- [ ] Implement connection quality monitoring
- [ ] Create fallback communication mechanisms
- [ ] Add connection status indicators in UI

### 2.5.3 Performance Optimization
- [ ] Implement message deduplication
- [ ] Create message priority queuing
- [ ] Add bandwidth optimization for mobile connections
- [ ] Implement lazy loading for conversation history
- [ ] Create message prefetching for better UX
- [ ] Add performance monitoring and analytics

## 2.6 Testing and Quality Assurance

### 2.6.1 LLM Integration Tests
- [ ] Create mock LLM server for testing
- [ ] Test streaming response handling and rendering
- [ ] Add conversation flow and state management tests
- [ ] Create channel communication integration tests
- [ ] Test error handling and recovery scenarios
- [ ] Add performance tests for message throughput

### 2.6.2 UI Component Tests
- [ ] Test conversation interface rendering
- [ ] Add message content rendering tests (markdown, code)
- [ ] Test code block actions and editor integration
- [ ] Create accessibility tests for chat interface
- [ ] Add responsive design tests
- [ ] Test keyboard navigation and shortcuts

### 2.6.3 End-to-End Testing
- [ ] Create full conversation flow tests
- [ ] Test Duck agent integration and responses
- [ ] Add multi-browser compatibility tests
- [ ] Test mobile and tablet interfaces
- [ ] Create load testing for concurrent conversations
- [ ] Add security testing for channel communications

## Dependencies and Prerequisites
- Phase 1: Core Foundation & Layout System (completed)
- External LLM coding assistant server with websocket API
- Phoenix Channels configured and tested
- Ash framework for domain modeling
- Prism.js for syntax highlighting
- Markdown parsing library

## Success Criteria
- [ ] Users can create and manage conversations with Duck
- [ ] Duck responses stream smoothly with progressive rendering
- [ ] Code blocks display with proper syntax highlighting
- [ ] Code actions (copy, apply) function correctly
- [ ] Conversation history persists and loads efficiently
- [ ] Channel communication is reliable and performant
- [ ] Mobile interface provides good user experience
- [ ] All tests pass with good coverage
- [ ] LLM server integration is stable and error-resilient

## Technical Notes
- Use Phoenix.PubSub for efficient message broadcasting
- Implement optimistic updates for message sending
- Consider using LiveView streams for conversation history
- Ensure proper sanitization of user input and LLM responses
- Pay attention to context window management for long conversations
- Implement proper error boundaries for LLM service failures

## Next Phase Dependencies
This phase provides the foundation for Phase 3 (Multi-user Collaborative Editor) by establishing:
- Reliable LLM communication patterns
- Conversation and message management
- Real-time websocket infrastructure
- UI patterns for collaborative features
- User session and context management