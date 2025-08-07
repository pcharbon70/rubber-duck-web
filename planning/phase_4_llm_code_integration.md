# Phase 4: Advanced LLM-Code Integration & Actions

## Overview
Integrate Duck (LLM assistant) with the collaborative code editor to enable intelligent code analysis, suggestions, and actions. This phase focuses on bi-directional communication between the editor and Duck, code-aware conversations, safe code execution, and advanced features like diff previews and automated code application.

## 4.1 Editor-Duck Communication Bridge

### 4.1.1 Code Context Extraction
```elixir
defmodule RubberduckWeb.Editor.ContextExtractor do
  def extract_context(editor_state, user_cursor_position) do
    %{
      full_content: editor_state.content,
      cursor_context: get_surrounding_lines(editor_state.content, user_cursor_position, 10),
      selected_content: get_selected_content(editor_state, user_cursor_position),
      file_type: detect_file_type(editor_state.language),
      syntax_tree: parse_syntax_tree(editor_state.content, editor_state.language),
      imports_and_dependencies: extract_imports(editor_state.content),
      function_definitions: extract_functions(editor_state.content),
      variable_scope: analyze_variable_scope(editor_state.content, user_cursor_position)
    }
  end
end
```
- [ ] Create code context extraction from Monaco Editor
- [ ] Implement cursor-aware context analysis
- [ ] Add syntax tree parsing for different languages
- [ ] Create semantic code analysis (imports, functions, variables)
- [ ] Set up file type detection and language-specific handling
- [ ] Add code quality metrics and complexity analysis

### 4.1.2 Real-time Code Sharing
- [ ] Create automatic code sharing when user asks Duck for help
- [ ] Implement selective code sharing (selection vs. full file)
- [ ] Add privacy controls for sensitive code sections
- [ ] Create code anonymization for external LLM services
- [ ] Set up code sharing permissions and user consent
- [ ] Add code sharing history and audit logging

### 4.1.3 Editor State Synchronization
```elixir
defmodule RubberduckWebWeb.EditorSyncChannel do
  use Phoenix.Channel
  
  def handle_in("request_code_analysis", %{"selection" => selection}, socket) do
    context = RubberduckWeb.Editor.ContextExtractor.extract_context(
      socket.assigns.editor_state, 
      selection
    )
    
    # Send context to Duck via LLM channel
    send_to_duck(socket.assigns.session_id, %{
      event: "code_analysis_request",
      context: context,
      user_query: selection["query"]
    })
    
    {:noreply, socket}
  end
end
```
- [ ] Create bi-directional editor-Duck communication channel
- [ ] Implement real-time editor state synchronization
- [ ] Add editor change notification to Duck conversations
- [ ] Create context-aware message routing
- [ ] Set up editor state persistence for Duck analysis
- [ ] Add editor state validation and error handling

## 4.2 Code-Aware Conversation Features

### 4.2.1 File Reference System
- [ ] Implement @ symbol mentions for file references in chat
- [ ] Create file browser and selection interface
- [ ] Add file content preview in chat messages  
- [ ] Set up file reference resolution and validation
- [ ] Create file reference permissions and access control
- [ ] Add file reference history and caching

### 4.2.2 Code Selection Integration
```heex
<div class="chat-message-with-code">
  <div class="message-content">
    <%= @message.content %>
  </div>
  
  <%= if @message.metadata.code_selection do %>
    <div class="code-selection-reference">
      <div class="code-preview">
        <pre><code class={"language-#{@message.metadata.language}"}>
          <%= @message.metadata.code_selection.content %>
        </code></pre>
      </div>
      <div class="selection-info">
        Lines <%= @message.metadata.code_selection.start_line %>-<%= @message.metadata.code_selection.end_line %>
        <button phx-click="jump_to_selection" phx-value-message-id={@message.id}>
          Jump to Code
        </button>
      </div>
    </div>
  <% end %>
</div>
```
- [ ] Add code selection sharing in chat messages
- [ ] Create "Jump to Code" functionality from chat
- [ ] Implement code selection highlighting in chat
- [ ] Add code selection context preservation
- [ ] Create code selection-based discussions
- [ ] Set up code selection versioning and tracking

### 4.2.3 Context-Aware Conversations
- [ ] Implement automatic context injection for Duck conversations
- [ ] Create context relevance scoring and filtering
- [ ] Add conversation branching based on code changes
- [ ] Set up context summarization for long conversations
- [ ] Create context-aware response generation
- [ ] Add context validation and consistency checking

## 4.3 Code Actions and Suggestions

### 4.3.1 Duck Code Suggestion System
```elixir
defmodule RubberduckWeb.CodeSuggestions.Suggestion do
  use Ash.Resource

  attributes do
    uuid_primary_key :id
    attribute :conversation_id, :string, allow_nil?: false
    attribute :suggestion_type, :atom, constraints: [one_of: [:replacement, :insertion, :deletion, :refactor]]
    attribute :target_range, :map  # {start_line, start_col, end_line, end_col}
    attribute :original_code, :string
    attribute :suggested_code, :string, allow_nil?: false
    attribute :explanation, :string
    attribute :confidence_score, :float
    attribute :status, :atom, constraints: [one_of: [:pending, :applied, :rejected, :modified]]
    timestamps()
  end
end
```
- [ ] Create code suggestion domain model
- [ ] Implement suggestion generation from Duck responses
- [ ] Add suggestion confidence scoring and ranking
- [ ] Create suggestion validation and safety checks
- [ ] Set up suggestion history and tracking
- [ ] Add suggestion conflict detection and resolution

### 4.3.2 Code Action Buttons
```heex
<div class="code-suggestion-actions">
  <div class="diff-preview">
    <%= render_code_diff(@suggestion.original_code, @suggestion.suggested_code) %>
  </div>
  
  <div class="action-buttons">
    <button phx-click="apply_suggestion" 
            phx-value-suggestion-id={@suggestion.id}
            class="btn-primary">
      Apply Changes
    </button>
    <button phx-click="preview_suggestion" 
            phx-value-suggestion-id={@suggestion.id}
            class="btn-secondary">
      Preview in Editor
    </button>
    <button phx-click="modify_suggestion" 
            phx-value-suggestion-id={@suggestion.id}
            class="btn-secondary">
      Modify
    </button>
    <button phx-click="reject_suggestion" 
            phx-value-suggestion-id={@suggestion.id}
            class="btn-danger">
      Reject
    </button>
  </div>
</div>
```
- [ ] Create code action buttons (Apply, Preview, Modify, Reject)
- [ ] Implement diff visualization for code suggestions
- [ ] Add code preview functionality before applying changes
- [ ] Create suggestion modification interface
- [ ] Set up batch suggestion application
- [ ] Add suggestion rollback and undo functionality

### 4.3.3 Safe Code Application
- [ ] Integrate SafeCode library for code validation
- [ ] Create code safety analysis before application
- [ ] Add user confirmation for potentially dangerous code
- [ ] Implement code sandboxing for testing suggestions
- [ ] Create code backup before applying changes
- [ ] Set up code application audit logging

## 4.4 Advanced LLM Features

### 4.4.1 Code Analysis and Insights
```elixir
defmodule RubberduckWeb.CodeAnalysis do
  def analyze_code_quality(code, language) do
    %{
      complexity_score: calculate_complexity(code),
      maintainability_index: calculate_maintainability(code),
      security_issues: detect_security_issues(code),
      performance_suggestions: analyze_performance(code),
      best_practice_violations: check_best_practices(code, language),
      test_coverage_suggestions: suggest_tests(code)
    }
  end
  
  def generate_documentation(code, language) do
    # Generate comprehensive code documentation
  end
  
  def suggest_refactoring(code, language) do
    # Identify refactoring opportunities
  end
end
```
- [ ] Implement automatic code quality analysis
- [ ] Create code documentation generation
- [ ] Add refactoring suggestion system
- [ ] Set up performance analysis and optimization suggestions
- [ ] Create security vulnerability detection
- [ ] Add test case generation suggestions

### 4.4.2 Interactive Code Exploration
- [ ] Create "Explain this code" functionality
- [ ] Implement step-by-step code walkthrough
- [ ] Add variable and function tracing
- [ ] Create interactive debugging assistance
- [ ] Set up code execution simulation
- [ ] Add code visualization and diagramming

### 4.4.3 Learning and Documentation
- [ ] Implement code concept explanation
- [ ] Create learning path suggestions based on code
- [ ] Add documentation search and reference
- [ ] Set up best practice recommendations
- [ ] Create code example generation
- [ ] Add technology stack analysis and suggestions

## 4.5 Code Execution and Testing

### 4.5.1 Safe Code Execution Engine
```elixir
defmodule RubberduckWeb.CodeExecution.SafeRunner do
  use GenServer
  
  def run_code(code, language, context \\ %{}) do
    with :ok <- SafeCode.Validator.validate(code),
         {:ok, sandbox} <- create_sandbox(language),
         {:ok, result} <- execute_in_sandbox(sandbox, code, context) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp create_sandbox(language) do
    # Create isolated execution environment
  end
  
  defp execute_in_sandbox(sandbox, code, context) do
    # Execute code safely with timeout and resource limits
  end
end
```
- [ ] Create safe code execution environment using SafeCode
- [ ] Implement language-specific execution engines
- [ ] Add execution timeout and resource limiting
- [ ] Create execution result formatting and display
- [ ] Set up code execution logging and monitoring
- [ ] Add execution environment cleanup and management

### 4.5.2 Interactive Testing
- [ ] Implement test case generation from Duck suggestions
- [ ] Create test execution and result display
- [ ] Add test coverage analysis and reporting
- [ ] Set up continuous testing during development
- [ ] Create test data generation and mocking
- [ ] Add test performance analysis and optimization

### 4.5.3 Code Validation and Linting
- [ ] Integrate language-specific linters and formatters
- [ ] Create real-time code validation during editing
- [ ] Add coding standard enforcement
- [ ] Set up automated code formatting suggestions
- [ ] Create custom linting rules based on project conventions
- [ ] Add code style consistency checking

## 4.6 Multi-language Support

### 4.6.1 Language Detection and Switching
- [ ] Implement automatic language detection from file extensions
- [ ] Create manual language switching interface
- [ ] Add language-specific Monaco Editor configurations
- [ ] Set up language-specific Duck conversation modes
- [ ] Create cross-language reference and linking
- [ ] Add language-specific help and documentation

### 4.6.2 Polyglot Project Support
- [ ] Create multi-language project analysis
- [ ] Implement cross-language dependency tracking
- [ ] Add polyglot refactoring suggestions
- [ ] Set up language interoperability analysis
- [ ] Create unified documentation across languages
- [ ] Add cross-language code generation

### 4.6.3 Language-Specific Features
- [ ] Implement language-specific code templates
- [ ] Create framework-aware suggestions (Phoenix, React, etc.)
- [ ] Add language-specific debugging tools
- [ ] Set up package manager integration
- [ ] Create language-specific performance analysis
- [ ] Add ecosystem-specific best practices

## 4.7 Testing and Quality Assurance

### 4.7.1 LLM-Code Integration Tests
- [ ] Test bi-directional editor-Duck communication
- [ ] Add code context extraction and analysis tests
- [ ] Create code suggestion generation and application tests
- [ ] Test safe code execution and validation
- [ ] Add multi-language support tests
- [ ] Create performance tests for code analysis features

### 4.7.2 Safety and Security Tests
- [ ] Test SafeCode integration and validation
- [ ] Add malicious code detection tests
- [ ] Create code execution sandbox security tests
- [ ] Test user permission and access control
- [ ] Add data privacy and code anonymization tests
- [ ] Create security audit logging tests

### 4.7.3 User Experience Tests
- [ ] Test code action button functionality
- [ ] Add diff visualization and preview tests
- [ ] Create code selection and sharing tests
- [ ] Test file reference system
- [ ] Add conversation context preservation tests
- [ ] Create mobile and accessibility tests for new features

## Dependencies and Prerequisites
- Phase 1-3: Foundation, Chat, and Collaborative Editor (completed)
- SafeCode library integration (completed)
- Monaco Editor with advanced language support
- External LLM service with code analysis capabilities
- Secure sandboxing environment for code execution
- Language-specific parsers and analyzers

## Success Criteria
- [ ] Duck can analyze and provide intelligent suggestions for code
- [ ] Code suggestions can be safely applied with diff previews
- [ ] File references and code selections work seamlessly in chat
- [ ] Safe code execution provides accurate results
- [ ] Context-aware conversations enhance coding productivity
- [ ] Multi-language support works across different programming languages
- [ ] Performance remains smooth with advanced LLM features
- [ ] Security and safety measures prevent malicious code execution
- [ ] All tests pass with comprehensive coverage
- [ ] User experience is intuitive and enhances coding workflow

## Technical Notes
- Implement proper code sandboxing to prevent security vulnerabilities
- Use debouncing for code analysis requests to prevent API overload
- Consider implementing local code analysis for privacy-sensitive projects
- Ensure proper error handling for LLM service failures
- Pay attention to code execution timeouts and resource management
- Implement comprehensive logging for debugging and monitoring

## Next Phase Dependencies
This phase provides advanced features for Phase 5 (Performance & Polish) by establishing:
- Sophisticated LLM-code integration patterns
- Safe code execution infrastructure
- Advanced conversation and context management
- Multi-language support framework
- Comprehensive testing and security measures