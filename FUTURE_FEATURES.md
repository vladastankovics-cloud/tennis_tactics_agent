# Future Features & Improvements

## Floating Chat Popup (Not Yet Implemented)

### Requirements:
- **Chat should be accessible from all screens via a floating button**
  - Position: Bottom right (similar to "+" button on matches screen)
  - Always visible/available across all screens

- **Chat popup behavior:**
  - Expands and collapses on button tap
  - Should be fairly thin (likely a slide-up panel or bottom sheet)
  - Overlays on top of current screen

- **Navigation changes:**
  - Remove current "Chat" tab from bottom navigation
  - Bottom nav should only have 2 tabs: Matches, Settings
  - Chat accessed via floating action button instead

### Implementation Notes:
- Use Overlay, OverlayEntry, or DraggableScrollableSheet for popup
- Make button global (available in all screens)
- Consider using a state management solution to manage chat state across screens
- Ensure popup doesn't interfere with existing FABs on specific screens

### Design Considerations:
- Popup height/width
- Animation style (slide up, fade in, etc.)
- Behavior when keyboard appears
- Close button or tap-outside-to-close
- Match current app theme and styling
