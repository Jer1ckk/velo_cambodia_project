# UI/UX Guidelines — Velo Cambo

## 1. Purpose and Scope

Use this document for visual redesigns and new UI features. General working rules belong in [AGENTS.md](../AGENTS.md); architecture, state management, data contracts, and known implementation limitations belong in [PROJECT_GUIDELINES.md](PROJECT_GUIDELINES.md).

For a visual-only task, preserve existing business rules, navigation results, repository contracts, and database formats. For an explicitly requested feature or behavior change, implement the supporting changes required by that request. Ask for clarification only when a consequential requirement remains unresolved; an already authorized change does not need separate approval merely because it affects data flow.

The token tables below describe the current [theme](../lib/ui/theme/theme.dart). Layout defaults and acceptance criteria are targets for new or changed UI, not claims that every existing screen already meets them. Apply them within the requested scope and report relevant gaps rather than silently expanding the task.

## 2. Design Direction

Aim for an Apple-inspired sense of clarity and restraint while retaining Flutter's Material controls and Velo Cambo's existing identity. Users should immediately understand station availability, their selected bike, and the next action.

- Give each screen one clear primary action; distinguish supporting actions by emphasis.
- Group related information with spacing before adding containers. Avoid cards nested inside cards.
- Use the warm brand palette and consistent typography. Avoid competing accents, decorative gradients, and ornamental icons.
- Default to flat surfaces and borders. Use elevation only to explain layering, such as a panel above the map.
- Use motion to explain selection, progress, or navigation; avoid motion that delays completing a task.

## 3. Theme and Layout Specification

Use `VeloColors`, `VeloTextStyles`, `VeloSpacings`, and `VeloSize` from the existing theme. Extend those definitions when a requested design needs another shared role; avoid creating a parallel token system. Review actual foreground/background pairs against section 7 before reusing them.

### 3.1 Color Roles

| Role | Existing token or theme property |
| --- | --- |
| Primary action | `VeloColors.primary` / `colorScheme.primary` |
| Text on primary | `VeloColors.neutralDark` / `colorScheme.onPrimary` |
| Supporting accent | `VeloColors.secondary` / `colorScheme.secondary` |
| Screen background | `VeloColors.background` |
| Surface | `VeloColors.white` / `colorScheme.surface` |
| Main text | `VeloColors.textNormal` / `colorScheme.onSurface` |
| Supporting text | `VeloColors.textLight` |
| Decorative border | `VeloColors.border` / `colorScheme.outlineVariant` |
| Control outline | `colorScheme.outline` |
| Status | `VeloColors.success`, `warning`, `error`, `info` and their `*Light` backgrounds |
| Disabled background | `VeloColors.disabled` |

Pair status color with text or a recognizable icon. Decorative border colors alone must not be the only way to identify an actionable control. The current theme defines a light theme; dark-mode support is a separate feature unless requested.

### 3.2 Typography

The current theme uses Flutter's default platform font. Sizes below are before system text scaling.

| Token | Size | Weight | Intended use |
| --- | ---: | --- | --- |
| `VeloTextStyles.heading` | 28 | w600 | Main screen heading |
| `VeloTextStyles.title` | 20 | w600 | Section or card title |
| `VeloTextStyles.body` | 16 | w400 | Main content |
| `VeloTextStyles.label` | 14 | w400 | Supporting information |
| `VeloTextStyles.button` | 14 | w600 | Action labels; color comes from button theme |

Use these roles before adding a new size. Let text and controls grow with system text scaling. Multiline text should use the font's natural line metrics; address clipping through layout rather than reducing font size or disabling scaling. Essential booking, price, and subscription information must remain fully readable.

### 3.3 Spacing

These are the actual `VeloSpacings` names and values, in logical pixels. There is currently no 4-pixel spacing token.

| Token | Value | Default use for changed UI |
| --- | ---: | --- |
| `VeloSpacings.xs` | 8 | Related labels, icon-to-text gaps |
| `VeloSpacings.s` | 12 | Compact group padding |
| `VeloSpacings.m` | 16 | Phone screen margins and card padding |
| `VeloSpacings.l` | 24 | Section gaps and wider screen margins |
| `VeloSpacings.xl` | 32 | Major content separation |
| `VeloSpacings.xxl` | 40 | Large section separation |

### 3.4 Component Defaults

| Element | Default for new or changed UI |
| --- | --- |
| Phone content margins | `VeloSpacings.m` (16) horizontally |
| Content margins at widths of 600 or more | `VeloSpacings.l` (24) horizontally |
| Cards and panels | Padding 16; radius `VeloSpacings.radius` (16) |
| Buttons and input fields | Radius 16; minimum interactive height 48 |
| Primary button | Existing elevated button theme; `VeloSize.buttonHeight` (48) minimum height, growing for wrapped labels |
| Modal bottom sheet | Upper corners `VeloSpacings.radiusLarge` (24); safe-area-aware content |
| Standard icon | `VeloSize.icon` (24) inside a touch target of at least 48 × 48 |
| Readable detail content on wide layouts | Proposed maximum width 600, centered; map canvas may fill available space |

Widths, margins, and the detail-content cap are layout targets, not existing breakpoint tokens or a declaration of tablet support. Adapt grids and map panels to available constraints without forcing every screen into the same layout. Keep primary actions reachable when the keyboard or system insets change.

### 3.5 Icons and Motion

Use Material icons consistently. Label navigation destinations and give icon-only actions tooltips and semantic labels. Keep decorative icons out of the screen-reader traversal when adjacent text already conveys their meaning.

Use built-in Flutter transitions when suitable. For custom selection or panel transitions, start with 150–250 ms and validate that interruptions remain responsive. Respect the platform's reduced-motion setting by removing nonessential motion; progress still needs a readable status.

## 4. Navigation and Screen Requirements

The current root destinations are Pass, Map, and Profile, with Map selected initially. A visual redesign retains this structure. Navigation changes require a functional requirement. Respect system back behavior, safe areas, and the space occupied by persistent navigation.

Screen names below are directories under `lib/ui/screens/`. They identify existing flows, not authorization to add missing product features. Display only information supported by models and actual data.

| Screen | Information and actions to prioritize | States to review |
| --- | --- | --- |
| `stations_map` | Map, recognizable station markers, selected station summary, route to station details; keep controls clear of panels | Loading, populated, empty, failure, selected station |
| `station` | Station name and availability, distinguish available/unavailable slots, selected bike or slot, booking action | Loading, failure, no available bikes, unselected and selected slots |
| `booking_bike` | Selected bike, relevant station and booking details, agreement and eligibility feedback, confirmation | Loading, invalid or unavailable action, submitting, failure, success navigation |
| `booking_bike_success` | Clear success message, actual booking details and pickup deadline where available, explicit continuation | Successful result, continuation and back navigation |
| `subscription` / `subscription_detail` | Compare pass price and duration, selected option, activation action, subscription status | Loading, available options, selection, submitting, failure, activation result |
| `profile` | Account information, current subscription and booking, status and expiry where supported | Loading, failure, no subscription, no booking, populated and expired information |

Booking success returns a result used to refresh station detail; see the mutation flow in the project guidelines before changing this interaction. Subscription prices and durations should have one authoritative source rather than contradictory copies. Static payment-card content does not establish payment-processing support.

## 5. Interaction and Feedback

### 5.1 Actions and Submission

Use action labels that describe the outcome, such as “Confirm booking.” Disable unavailable actions and show the reason nearby when it is not obvious. During submission, show progress and prevent repeated requests. Present success only after the required operation completes; retain relevant selection or input after failure.

Use confirmation dialogs when an action has consequences that need explanation. Routine station selection and navigation should not require confirmation.

### 5.2 Loading, Empty, and Error States

- Loading: keep the screen's context visible and label the pending operation, such as “Loading stations.” Do not leave an unexplained spinner as the entire experience.
- Empty: explain what is unavailable, such as “No current booking.” Offer a relevant next action when supported. An empty collection is a successful result, not an error.
- Error: explain the problem in product language, preserve usable content or input, and offer recovery when supported. Do not render raw exceptions or stack traces.
- Retry: connect the action to a real reload or resubmission path. If recovery requires a change outside a visual task's scope, report that gap and apply the scope rule in section 1.

For asynchronous state types and current error-handling limitations, use the project guidelines as the implementation reference.

## 6. Components and Implementation References

Reuse existing Flutter/Material controls and suitable local components before extracting another abstraction. Keep a component in its feature directory until it has a concrete shared use; shared widgets belong in `lib/ui/widgets/`.

Existing reuse points include `SubscriptionStatusBadge`, `DateTimeUtils`, and the theme tokens above. These names do not imply that a complete component library already exists.

Follow [project architecture and responsibilities](PROJECT_GUIDELINES.md#3-architecture-and-layer-responsibilities) and [state management and data flow](PROJECT_GUIDELINES.md#7-state-management-and-data-flow) for Provider, ViewModels, services, repositories, and the custom `AsyncValue<T>`. Follow [AGENTS.md](../AGENTS.md) for dependencies, coding conventions, scope, and validation reporting.

## 7. Responsive Layout and Accessibility Acceptance Criteria

The following are project acceptance targets for changed UI. They do not establish that all scaffolded platforms are supported or that existing screens comply.

### 7.1 Layout Test Matrix

Review changed screens at these logical viewport sizes, using a simulator/device or equivalent constrained preview:

| Viewport | Purpose |
| --- | --- |
| 320 × 568 | Compact phone and short content area |
| 390 × 844 | Typical phone |
| 844 × 390 | Phone landscape |
| 768 × 1024 | Wider-layout check when tablet/wide support is in scope |

At the phone sizes, check default text scaling and a 2.0 text scale using Flutter's text-scaling mechanism. Also inspect any intermediate scale that exposes a layout issue. Do not cap system text scaling to make a check pass.

Acceptance means no overflow warnings, clipped essential text, overlapping controls, or unreachable actions. Scroll long content, wrap labels, and let controls grow instead of fixing content heights. Check safe areas, bottom navigation, and keyboard visibility for screens with inputs. Preserve full essential values; reserve ellipsis for secondary summaries with an accessible way to read the full text.

### 7.2 Contrast and Touch

- Target text contrast of at least 4.5:1 for all app text, including supporting text and action labels, against its actual background.
- Target at least 3:1 for meaningful control boundaries, focus indicators, and status icons against adjacent colors. Decorative separators are exempt; they must not carry essential meaning.
- Give interactive controls a hit area of at least 48 × 48 logical pixels, even when the visible icon is 24. Adjacent targets must not overlap.
- Identify selected, unavailable, success, and error states with text, shape, or icons as well as color.
- Measure color pairs; use of a theme token alone does not demonstrate sufficient contrast. Record relevant failures rather than claiming the whole palette passes.

### 7.3 Assistive Technology and Motion

Verify changed interactions with TalkBack on Android or VoiceOver on iOS for each platform in the task's scope:

- Controls announce an understandable name, role, and selected/disabled state.
- Reading and focus order follow the visible content, and dialogs return focus sensibly.
- Loading, validation, errors, and submission results are discoverable without relying on visual animation.
- Station selection and booking remain possible through accessible controls; provide a station list or equivalent path if the map markers cannot support this. Such a path is a feature requirement to scope under section 1, not an assumed existing capability.
- Reduced-motion settings remove nonessential custom transitions without hiding status or preventing completion.

## 8. Review and Delivery

Use the implementation workflow in the root `AGENTS.md`. For a UI task, add this focused review:

1. Inspect the target screen, its theme usage, current interactions, and relevant known limitations in the project guidelines.
2. Define the layout and state changes, reusable components, acceptance checks, and affected files before implementation. A short note is sufficient for a small change.
3. Implement the requested UI using section 3 and the scope rules in section 1.
4. Exercise the screen states in section 4, the interaction behavior in section 5, and the applicable viewport and accessibility checks in section 7. Run relevant source checks from the project guidelines.
5. Report changed behavior and files, validation actually performed, and remaining gaps. Distinguish a code inspection from a device or screen-reader test.

Completion checklist:

- [ ] Theme roles, spacing, component sizes, and typography follow section 3, with any justified deviations recorded.
- [ ] The primary action and important station, price, subscription, or booking information are clear.
- [ ] Relevant loading, empty, selection, submission, error, and success states have been exercised.
- [ ] Navigation results and refresh behavior match the requested scope.
- [ ] Applicable viewport, text-scaling, contrast, touch-target, screen-reader, and reduced-motion checks are recorded with their outcomes.
- [ ] Unsupported or untested states, platforms, and accessibility gaps are stated explicitly.

Keep these guidelines synchronized with intentional theme or product changes. Update the relevant source-of-truth section instead of duplicating its rules elsewhere.
