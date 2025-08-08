/**
 * ResizeHandle Hook for Phoenix LiveView
 * 
 * Implements draggable resize functionality for split panels.
 * Allows users to drag the divider between editor and chat panels
 * to adjust their relative sizes.
 */

export default {
  mounted() {
    this.initializeResize();
  },

  initializeResize() {
    this.isDragging = false;
    this.startX = 0;
    this.startEditorWidth = 0;
    this.startChatWidth = 0;
    this.container = null;
    
    // Minimum widths (in pixels)
    this.minEditorWidth = 400;
    this.minChatWidth = 280;
    
    // Find the container and panels
    this.container = this.el.closest('.collaborative-panels');
    if (!this.container) {
      console.warn('ResizeHandle: Could not find collaborative-panels container');
      return;
    }
    
    this.editorPanel = this.container.querySelector('#code-editor');
    this.chatPanel = this.container.querySelector('.chat-sidebar');
    
    if (!this.editorPanel || !this.chatPanel) {
      console.warn('ResizeHandle: Could not find editor or chat panels');
      return;
    }
    
    // Bind event handlers
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleDoubleClick = this.handleDoubleClick.bind(this);
    
    // Add event listeners
    this.el.addEventListener('mousedown', this.handleMouseDown);
    this.el.addEventListener('dblclick', this.handleDoubleClick);
    
    // Add visual feedback
    this.addVisualStyles();
  },
  
  addVisualStyles() {
    this.el.style.cursor = 'col-resize';
    this.el.style.userSelect = 'none';
    this.el.style.transition = 'background-color 0.2s ease';
    
    // Add hover effect
    this.el.addEventListener('mouseenter', () => {
      this.el.style.backgroundColor = 'rgba(59, 130, 246, 0.1)'; // Primary color with opacity
    });
    
    this.el.addEventListener('mouseleave', () => {
      if (!this.isDragging) {
        this.el.style.backgroundColor = 'transparent';
      }
    });
  },
  
  handleMouseDown(event) {
    event.preventDefault();
    
    this.isDragging = true;
    this.startX = event.clientX;
    
    // Get current dimensions
    const containerRect = this.container.getBoundingClientRect();
    const editorRect = this.editorPanel.getBoundingClientRect();
    const chatRect = this.chatPanel.getBoundingClientRect();
    
    this.containerWidth = containerRect.width;
    this.startEditorWidth = editorRect.width;
    this.startChatWidth = chatRect.width;
    
    // Add global event listeners
    document.addEventListener('mousemove', this.handleMouseMove);
    document.addEventListener('mouseup', this.handleMouseUp);
    
    // Visual feedback during drag
    this.el.style.backgroundColor = 'rgba(59, 130, 246, 0.2)';
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
    
    // Prevent text selection during drag
    event.stopPropagation();
  },
  
  handleMouseMove(event) {
    if (!this.isDragging) return;
    
    event.preventDefault();
    
    const deltaX = event.clientX - this.startX;
    const newEditorWidth = this.startEditorWidth + deltaX;
    const newChatWidth = this.startChatWidth - deltaX;
    
    // Check minimum width constraints
    if (newEditorWidth < this.minEditorWidth || newChatWidth < this.minChatWidth) {
      return;
    }
    
    // Calculate percentages
    const editorPercent = Math.round((newEditorWidth / this.containerWidth) * 100);
    const chatPercent = Math.round((newChatWidth / this.containerWidth) * 100);
    
    // Ensure percentages add up to 100
    const totalPercent = editorPercent + chatPercent;
    if (totalPercent !== 100) {
      const adjustment = 100 - totalPercent;
      const adjustedChatPercent = chatPercent + adjustment;
      
      // Update layout immediately for smooth dragging
      this.updatePanelWidths(editorPercent, adjustedChatPercent);
    } else {
      this.updatePanelWidths(editorPercent, chatPercent);
    }
  },
  
  handleMouseUp(event) {
    if (!this.isDragging) return;
    
    this.isDragging = false;
    
    // Remove global event listeners
    document.removeEventListener('mousemove', this.handleMouseMove);
    document.removeEventListener('mouseup', this.handleMouseUp);
    
    // Reset visual feedback
    this.el.style.backgroundColor = 'transparent';
    document.body.style.cursor = 'default';
    document.body.style.userSelect = 'auto';
    
    // Get final percentages and send to LiveView
    const containerRect = this.container.getBoundingClientRect();
    const editorRect = this.editorPanel.getBoundingClientRect();
    const chatRect = this.chatPanel.getBoundingClientRect();
    
    const editorPercent = Math.round((editorRect.width / containerRect.width) * 100);
    const chatPercent = Math.round((chatRect.width / containerRect.width) * 100);
    
    // Send update to LiveView
    this.pushEvent('update_layout', {
      config: {
        editor_width_percent: editorPercent,
        chat_width_percent: chatPercent
      }
    });
    
    // Persist to localStorage
    this.persistLayout(editorPercent, chatPercent);
  },
  
  handleDoubleClick(event) {
    event.preventDefault();
    
    // Reset to default 70/30 split
    const defaultEditorPercent = 70;
    const defaultChatPercent = 30;
    
    this.updatePanelWidths(defaultEditorPercent, defaultChatPercent);
    
    // Send update to LiveView
    this.pushEvent('update_layout', {
      config: {
        editor_width_percent: defaultEditorPercent,
        chat_width_percent: defaultChatPercent
      }
    });
    
    // Persist to localStorage
    this.persistLayout(defaultEditorPercent, defaultChatPercent);
    
    // Visual feedback for double-click reset
    this.el.style.backgroundColor = 'rgba(34, 197, 94, 0.2)'; // Success color
    setTimeout(() => {
      this.el.style.backgroundColor = 'transparent';
    }, 200);
  },
  
  updatePanelWidths(editorPercent, chatPercent) {
    // Update panel widths immediately for smooth interaction
    if (this.editorPanel) {
      this.editorPanel.style.width = `${editorPercent}%`;
    }
    if (this.chatPanel) {
      this.chatPanel.style.width = `${chatPercent}%`;
    }
  },
  
  persistLayout(editorPercent, chatPercent) {
    try {
      const layoutData = {
        editor_width_percent: editorPercent,
        chat_width_percent: chatPercent,
        timestamp: Date.now()
      };
      localStorage.setItem('rubberduck_layout_config', JSON.stringify(layoutData));
    } catch (error) {
      console.warn('ResizeHandle: Could not persist layout to localStorage:', error);
    }
  },
  
  destroyed() {
    // Cleanup event listeners
    if (this.isDragging) {
      document.removeEventListener('mousemove', this.handleMouseMove);
      document.removeEventListener('mouseup', this.handleMouseUp);
    }
  }
};