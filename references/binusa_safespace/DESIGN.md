---
name: Binusa SafeSpace
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#444651'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#4759a7'
  on-secondary: '#ffffff'
  secondary-container: '#98a9fd'
  on-secondary-container: '#283b88'
  tertiary: '#4b1c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#6e2c00'
  on-tertiary-container: '#f39461'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#dde1ff'
  secondary-fixed-dim: '#b8c3ff'
  on-secondary-fixed: '#001355'
  on-secondary-fixed-variant: '#2e408d'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb691'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#773205'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.5px
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-mobile: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  card-padding: 20px
---

## Brand & Style

The design system is centered on a **Corporate Modern** aesthetic tailored for the educational sector. It balances the authority required for disciplinary matters with the empathy needed for counseling. The visual narrative focuses on "Stability through Structure," using a mobile-first approach that prioritizes clarity and high trust. 

The mood is professional and accessible, avoiding overly playful elements to maintain the seriousness of the subject matter. It leverages Material Design 3 principles—specifically its logic for hierarchy and interaction—but elevates them with custom elevation and a signature gradient style to differentiate the experience from standard utility apps.

## Colors

The palette is anchored by a deep blue gradient that symbolizes wisdom, trust, and security. This gradient should be used for primary action containers, header backgrounds, and significant brand moments. 

- **Primary:** Deep Blue (#1E3A8A) to Midnight (#001A6A).
- **Secondary:** Subtle Grays (#F1F5F9, #E2E8F0) used for background surfaces and inactive states to keep the interface light and breathable.
- **Urgent/Action:** A high-visibility Red (#DC2626) is reserved exclusively for "Submit Form" highlights, urgent status badges, or critical alerts to ensure cognitive load is directed where attention is most needed.
- **Background:** Pure White (#FFFFFF) is the primary surface color to maintain a clean, academic feel.

## Typography

The design system utilizes **Inter** for its exceptional legibility on mobile screens and its neutral, systematic tone. 

- **Headlines:** Use Bold or Semi-Bold weights with slight negative letter-spacing to create a strong visual anchor for page titles.
- **Body:** Standardized at 16px for primary reading (counseling notes, articles) to ensure accessibility for all users, including parents and staff.
- **Labels:** Used for status badges and button text, employing uppercase or medium weights to distinguish them from flowable text.
- **Hierarchy:** Maintain a strict vertical rhythm. Headlines should always be primary deep blue, while body text uses a dark slate (#1E293B) to reduce eye strain compared to pure black.

## Layout & Spacing

This design system uses a **Fluid Grid** model optimized for mobile-first delivery. 

- **Margins:** A consistent 20px outer margin ensures content does not feel cramped against device edges.
- **Grid:** A 4-column layout for mobile, where cards typically span the full width (4 columns) to maximize touch targets.
- **Vertical Rhythm:** An 8px base-unit system guides all padding and margins. 
- **Safe Areas:** Adhere strictly to mobile safe-areas, especially for bottom-fixed "Submit" buttons and navigation bars.

## Elevation & Depth

To create a high-trust, professional environment, this design system utilizes **Ambient Shadows** and **Tonal Layers**. 

- **Shadows:** Use extra-diffused shadows with a slight blue tint (`rgba(30, 58, 138, 0.08)`) rather than pure black. This prevents the UI from feeling "dirty" and reinforces the brand color.
- **Tiers:** 
  - **Level 0 (Base):** Subtle Gray (#F8FAFC) background.
  - **Level 1 (Cards):** White surfaces with soft shadows for content modules.
  - **Level 2 (Active/Urgent):** High-contrast primary gradient for floating action buttons or active state highlights.
- **Depth:** Avoid heavy skeuomorphism. Depth is used functionally to indicate what is tappable (raised) versus what is informational (flat).

## Shapes

The shape language is defined by significant **Roundedness** to evoke a sense of safety and approachability.

- **Cards:** Defined by a 24px corner radius (`rounded-xl`). This is the signature element of the design system, creating a "bubble of safety" for sensitive counseling information.
- **Buttons:** 12px corner radius for a modern, professional look that isn't as playful as a full pill shape but softer than standard corporate blocks.
- **Inputs:** 8px corner radius to maintain a sense of structured data entry.
- **Iconography:** Use rounded-corner icons (Material Symbols Rounded) to match the component geometry.

## Components

- **Buttons:** Primary buttons use the brand gradient with white text. "Submit" buttons for forms or urgent reporting use the Red accent color.
- **Cards:** The workhorse of the system. Every card must have a 24px radius, a 20px internal padding, and the signature light-blue ambient shadow.
- **Status Badges:** Small, rounded containers (8px radius). High-priority disciplinary items use the Red accent with white text; counseling appointments use a light blue tint.
- **Input Fields:** Outlined style with a 1px border (#E2E8F0). On focus, the border thickens to 2px and changes to the Primary Blue.
- **Progress Indicators:** Linear bars for tracking disciplinary steps or counseling milestones, using the brand gradient for the filled portion.
- **Navigation:** A clean bottom navigation bar with active states indicated by a subtle blue tinted glow behind the icon.