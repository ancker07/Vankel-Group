# Vanakel Group — UI Theme & Styling Guide

This document defines the official UI/UX design system for the Vanakel Group Management Platform. The theme is designed to be **professional, high-contrast, and dark-mode first**, suitable for both Admin (Contractor) and Syndic (Client) roles.

## 1. Color Palette

### Primary Colors
- **Brand Black (`#0a0a0a`)**: Used as the global background for the entire application. Deep, neutral, and reduces eye strain.
- **Brand Green (`#22c55e`)**: The primary accent color. Used for:
  - Active states (Sidebar navigation)
  - Primary actions (though buttons are often White)
  - Success states (Completed interventions)
  - Icons and highlights
- **Brand Orange (`#f97316`)**: Used for:
  - "Maintenance" occurrences (distinct from standard interventions)
  - "Delayed" status
  - Warnings or alerts

### Neutral Scale (Zinc)
We use the Tailwind `zinc` scale for a metal/industrial feel appropriate for construction management.
- **Surface (`zinc-950` / `#09090b`)**: Card backgrounds, Modal backgrounds.
- **Element (`zinc-900` / `#18181b`)**: Input fields, Headers, Hover states.
- **Border (`zinc-800` / `#27272a`)**: Subtle dividers and borders.
- **Text Primary (`zinc-300` / `#d4d4d8`)**: Main content text.
- **Text Secondary (`zinc-500` / `#71717a`)**: Metadata, labels, inactive icons.

## 2. Typography
- **Font Family**: `Inter` (Sans-serif). Clean, modern, and highly legible.
- **Weights**:
  - `Regular (400)`: Body text.
  - `Medium (500)`: Labels, secondary actions.
  - `Bold (700)`: Headings, important values.
  - `Black (900)`: Uppercase badges, major section headers.

## 3. Component Styling Patterns

### Cards (Building, Intervention, Property)
Standard container for data items.
```jsx
className="bg-zinc-950 border border-zinc-800 p-5 rounded-2xl"
```
- **Hover Effect**: `hover:border-brand-green/30` (Subtle green glow on border).

### Buttons
- **Primary Action**: High contrast.
  ```jsx
  className="bg-white text-black hover:bg-zinc-200 font-bold rounded-xl px-4 py-2"
  ```
- **Secondary Action**: Integrated with dark theme.
  ```jsx
  className="bg-zinc-900 text-white border border-zinc-800 hover:bg-zinc-800"
  ```
- **Destructive**:
  ```jsx
  className="bg-red-500/10 text-red-500 hover:bg-red-500/20"
  ```

### Inputs & Forms
```jsx
className="bg-zinc-950 border border-zinc-800 text-white rounded-xl focus:border-brand-green outline-none"
```

### Badges & Status Indicators
Small uppercase labels to show status.
- **Pending/Normal**: `bg-zinc-800 text-zinc-400 border border-zinc-700`
- **Maintenance/Delayed**: `bg-orange-500/10 text-orange-500 border border-orange-500/20`
- **Completed/Success**: `bg-brand-green/10 text-brand-green border border-brand-green/20`

## 4. Layout & Navigation (Sidebar)
- **Container**: `bg-zinc-950 border-r border-zinc-800`
- **Active Item**:
  ```jsx
  className="bg-brand-green/10 text-brand-green font-semibold border-l-4 border-brand-green"
  ```
- **Inactive Item**: `text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200`

## 5. CSS Configuration (Tailwind)

Ensure your `tailwind.config.js` includes the following extension:

```javascript
theme: {
  extend: {
    colors: {
      brand: {
        black: '#0a0a0a',
        green: '#22c55e',
        orange: '#f97316'
      }
    }
  }
}
```
