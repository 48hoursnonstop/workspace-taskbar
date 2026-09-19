# UX direction

## Aesthetic

Refined utilitarian Omarchy-native taskbar. The memorable element is not extra chrome; it is the precision of state feedback. Window icons remain the AppLibrary icons users already recognize. A compact state rail and a small Pop marker carry taskbar-specific identity.

## Interaction hierarchy

Primary actions stay on direct manipulation:

- left click: focus, minimize active, or restore minimized;
- middle click: close exact instance;
- right click: concise context menu;
- Show Desktop: left click toggles the desktop; right click switches the current workspace between Omarchy's Dwindle and Scrolling layouts; no maintenance action is assigned to middle click.

The right-click menu uses progressive disclosure. Frequent actions remain on the main page. Rare compositor operations live under **More window actions…**. Workspace selection remains a dedicated page. Close stays explicit and uses the urgent semantic color.

## Iconography

Application identity remains AppLibrary-only. Taskbar-owned controls and context-menu actions use a small bundled subset of Lucide SVGs, tinted with Omarchy semantic colors at render time. Icons clarify existing actions; they never become a second launcher-identity resolver or replace text labels in menus.

## Motion

The motion language is fast, controlled, and functional.

- hover / direct feedback: about 90–100 ms;
- state changes: about 120–150 ms;
- attention settle: at most about 180 ms;
- easing: `Easing.OutCubic` unless a host Omarchy component already defines its own timing;
- honor the host bar animation gate; when it is disabled, taskbar-only micro-motion resolves immediately;
- animate scale and opacity for new microinteractions; do not animate taskbar layout geometry for state changes;
- urgency receives one short attention pulse when it arrives, never a perpetual animation.

## State vocabulary

- **Active:** accent rail at full extent plus selected surface.
- **Inactive:** shorter, lower-opacity foreground rail.
- **Minimized:** shortest rail and reduced icon opacity.
- **Urgent:** urgent semantic color plus one arrival pulse.
- **Popped:** accent rail plus a small accent diamond; this marker means the project-created reversible Pop state, not generic floating/pinned state.
- **Busy:** icon softens and an accent activity dot appears until the exact-address action completes.

## Constraints

No custom launcher identities, no custom icon resolver, no Omarchy source modification, no extra Quickshell process, no Hyprbars fork, and no architecture decisions sourced from web/frontend-oriented design guidance.

## Keyboard and accessibility

Pointer behavior remains primary for the bar, but every custom window button exposes Qt button semantics and the same exact-window primary action through Enter/Space. Menu/Shift+F10 opens the context menu. Popup rows use visible Omarchy focus styling, skip disabled actions during Up/Down traversal, support Right to enter submenus, Left to return, and Escape to dismiss. Accessibility press actions must execute the same command as the corresponding pointer action.
