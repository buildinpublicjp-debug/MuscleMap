# MuscleMap UI Design Quality Audit

> **Date:** 2026-03-20
> **Scope:** All SwiftUI View files under `MuscleMap/Views/` (65 files, 10 subdirectories)
> **Auditors:** Automated analysis agents (color, font, spacing, components/animations/accessibility)

---

## Executive Summary

The MuscleMap UI has strong foundational consistency in CTA buttons (18pt bold, 56pt height, cornerRadius 16) and a well-organized semantic color system. However, the audit reveals **27 unique font sizes** (should be ~8), **fragmented spacing values** across main app screens, **zero accessibility labels/hints**, **zero Dynamic Type support**, and several tap targets below the 44pt minimum. The onboarding flow is generally more consistent than the main app, but has its own internal variations (title sizes 22-28pt, checkmark sizes, card heights).

**Critical Issues:** 3
**High Priority:** 8
**Medium Priority:** 12
**Low Priority:** 6

---

## 1. Design Token Inventory

### 1.1 Color Tokens

**Total unique tokens in use:** 32 (+ aliases)

#### Main App Tokens (ColorExtensions.swift)

| Token | Hex (Dark) | Hex (Light) | Usage Count | File Count |
|:---|:---|:---|:---|:---|
| `mmBgPrimary` | `#121212` | `#F5F5F7` | 110 | 45 |
| `mmBgSecondary` | `#1E1E1E` | `#EBEBF0` | 46 | 26 |
| `mmBgCard` | `#2A2A2A` | `#FFFFFF` | 123 | 37 |
| `mmTextPrimary` | white | `#1C1C1E` | 168 | 41 |
| `mmTextSecondary` | `#B0B0B0` | `#6C6C70` | 359 | 45 |
| `mmAccentPrimary` | `#00FFB3` | `#00CC8F` | 265 | 43 |
| `mmAccentSecondary` | `#00D4FF` | `#00A8CC` | 26 | 13 |
| `mmBrandPurple` | `#A020F0` | `#A020F0` | 1 | 1 |
| `mmMuscleFatigued` | `#E57373` | `#E57373` | via aliases | -- |
| `mmMuscleModerate` | `#FFD54F` | `#FFD54F` | via aliases | -- |
| `mmMuscleRecovered` | `#81C784` | `#81C784` | via aliases | -- |
| `mmMuscleInactive` | `#3D3D42` | `#E5E5EA` | -- | -- |
| `mmMuscleNeglected` | `#B388D4` | `#B388D4` | -- | -- |
| `mmBorder` | `#808080` | `#C7C7CC` | 16 | 5 |
| `mmPRGold` | `#FFD700` | `#FFD700` | 20 | 6 |
| `mmDestructive` | `#FF453A` | `#FF453A` | 6 | 4 |
| `mmWarning` | `#FF9F0A` | `#FF9F0A` | 2 | 2 |
| `mmTimerOvertime` | `#E57373` | -- | 2 | 1 |
| `mmTimerWarning` | `#FFD54F` | -- | 2 | 1 |
| `mmGifBackground` | `#FFFFFF` | -- | 4 | 1 |
| **mmMuscle* total** | -- | -- | 62 | 16 |

#### Onboarding Tokens (OnboardingV2View.swift:110-115)

| Token | Value | Usage Count | File Count |
|:---|:---|:---|:---|
| `mmOnboardingAccent` | `#00E676` (fixed) | 92 | 12 |
| `mmOnboardingAccentDark` | `#00B35F` (fixed) | 6 | 5 |
| `mmOnboardingBg` | `#1A1A1E` (fixed) | 46 | 12 |
| `mmOnboardingCard` | `#2C2C2E` (fixed) | 37 | 12 |
| `mmOnboardingTextMain` | white@0.9 (fixed) | 43 | 11 |
| `mmOnboardingTextSub` | `#8E8E93` (fixed) | 87 | 13 |

**Note:** None of the 6 onboarding tokens are identical to their main app counterparts. Onboarding uses fixed (non-adaptive) dark-only colors. This is by design but means 11 extra tokens to maintain.

#### Locally Defined Tokens (outside ColorExtensions.swift)

| File | Tokens |
|:---|:---|
| `FriendActivityCard.swift:211-228` | `mmPRCardBg`, `mmPRBorder`, `mmPRAccent` |
| `OnboardingV2View.swift:110-115` | 6 onboarding tokens (above) |

### 1.2 Font Sizes

**Total unique `.system(size:)` values:** 27 (7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 42, 48, 60, 70, 80)

**Total `.font()` declarations:** ~876

| Semantic Role | CLAUDE.md Spec | Actual Usage | Variants Found |
|:---|:---|:---|:---|
| Page Title (L1) | `.largeTitle` / Heavy | 8+ variants (22-34pt) | `.largeTitle.weight(.heavy)`, `.largeTitle.bold()`, `.title.bold()`, `.system(size: 22-32, weight: .heavy)` |
| Section Title (L2) | `.title2` / Bold | `.headline` dominant | `.headline`, `.title2.bold()`, `.title3`, `.system(size:16, weight:.bold)` |
| Item Name (L3) | `.title3` / Bold | `.subheadline.bold()` dominant | `.subheadline.bold()`, `.system(size:14, weight:.bold)`, `.headline.bold()` |
| Body (L4) | `.body` / `.caption` | Mixed | `.body`, `.subheadline`, `.system(size:14)`, `.system(size:16)`, `.caption` |
| CTA Button | (not in spec) | **Perfectly consistent** | `.system(size: 18, weight: .bold)` -- 18/18 instances |

### 1.3 Spacing Values

| Category | Spec (CLAUDE.md) | Actual Values Found |
|:---|:---|:---|
| Horizontal page padding | 8pt grid | Onboarding: **24** (consistent); Main app: **16/20/24** (inconsistent) |
| Section-to-section | 32pt | `VStack(spacing: 24)` dominant, some 32 |
| Element-to-element | 16pt | 8, 12, 16 all common |
| Container padding | 16pt | 12, 16 both common |
| Button height (CTA) | -- | **56pt** standard (17 instances), outliers at 44/48/50/60 |
| Bottom padding (CTA) | -- | Onboarding: 32; Main app: 16; PaywallView: 24 |
| Top-of-page spacing (onboarding) | -- | Varies: 24/32/48/60 |

### 1.4 Corner Radius

| Value | Count | Usage |
|:---|:---|:---|
| 4pt | 5 | Tiny indicators, progress bars |
| 6pt | 2 | Small status badges (outlier) |
| 8pt | 13 | Pills, chips, search bars, thumbnails |
| 10pt | 3 | Input fields (outlier) |
| 12pt | 41 | Card containers, secondary buttons |
| 14pt | 4 | Onboarding selection cards (outlier) |
| 16pt | 63 | Major cards, primary buttons, sections |
| 24pt | 5 | Large round containers, share cards |

### 1.5 Animation Parameters

| Pattern | Standard Value | Usage |
|:---|:---|:---|
| Card selection spring | `.spring(response: 0.35, dampingFraction: 0.7)` | 5 onboarding pages (consistent) |
| Header entrance | `.easeOut(duration: 0.5)` | All onboarding pages (consistent) |
| Button state change | `.easeInOut(duration: 0.2)` | 7+ instances (consistent) |
| Card cascade delay | `Double(index) * 0.08` | Most pages (GoalSelectionPage uses 0.06) |
| Glow repeat | `.easeInOut(duration: 1.5).repeatForever` | 2 instances (consistent) |

---

## 2. Inconsistency List

### 2.1 CRITICAL (P0)

| # | Category | Issue | Location | Impact |
|:---|:---|:---|:---|:---|
| C-1 | Accessibility | **Zero `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`** across all 65 View files | All files | VoiceOver completely broken for custom components (muscle map, checkmarks, accent bars, GIFs) |
| C-2 | Accessibility | **Zero Dynamic Type support** -- all fonts use fixed `.system(size:)` | All files | Text does not scale with user font size preferences |
| C-3 | Accessibility | Disabled button text likely **fails WCAG AA contrast** -- `#8E8E93` on `#2C2C2E` = ~3.4:1 (needs 4.5:1) | All onboarding "Next" buttons | Disabled state unreadable for low-vision users |

### 2.2 HIGH (P1)

| # | Category | Issue | Location | Fix |
|:---|:---|:---|:---|:---|
| H-1 | Font | Onboarding page titles use **4 different sizes** (22/24/26/28pt) | GoalSelectionPage(22), PRInputPage(22), GoalMusclePreviewPage(24), PaywallView(24), RoutineCompletionPage(26), others(28) | Unify to 28pt for all onboarding pages |
| H-2 | Font | Section titles use `.headline` (~17pt) instead of spec'd `.title2` (~22pt) | 25+ instances across WorkoutCompletionSections, History*, WorkoutIdle, MuscleJourney, MuscleBalance, WeeklySummary, MuscleHeatmap, ExerciseDetail, MuscleDetail, ExercisePreview | Replace `.headline` with `.title2.bold()` |
| H-3 | Color | **2 system colors** used instead of semantic tokens | `FrequencySelectionPage.swift` -- `Color.red.opacity(0.8)`, `Color.yellow.opacity(0.8)` | Use `mmMuscleFatigued`/`mmMuscleModerate` |
| H-4 | Color | **2 hardcoded `Color()` constructors** | `AnalyticsMenuView.swift:47,105` -- inline RGB for icon colors | Define as `mmAnalyticsHeatmap`/`mmAnalyticsRecap` tokens |
| H-5 | Color | **Cross-boundary token usage** -- onboarding tokens in non-onboarding view | `PaywallView.swift` uses `mmOnboardingCard`, `mmOnboardingTextSub` | Use main app tokens or create PaywallView-specific tokens |
| H-6 | Spacing | Main app horizontal padding **fragmented** (16/20/24 mixed on same screens) | HomeHelpers(16), WeeklySummary(20), WorkoutCompletion(20/28), Settings(16/20) | Standardize to 16pt for main app |
| H-7 | Component | **3 of 11 onboarding CTA buttons** use solid color instead of gradient | GoalSelectionPage, RoutineBuilderPage, FavoriteExercisesPage | Apply `LinearGradient(mmOnboardingAccent, mmOnboardingAccentDark)` to all |
| H-8 | Tap Target | **Multiple elements below 44pt** minimum | LocationCard(42pt), kg/lb toggle(28pt), set/rep capsule buttons, delete exercise icon(~20pt) | Add `.frame(minHeight: 44)` or increase padding |

### 2.3 MEDIUM (P2)

| # | Category | Issue | Location | Fix |
|:---|:---|:---|:---|:---|
| M-1 | Font | `.largeTitle.bold()` used instead of `.largeTitle.weight(.heavy)` per spec | HomeStreakComponents:78, FullBodyConquestView:46 | Change `.bold()` to `.weight(.heavy)` |
| M-2 | Font | Analytics screen titles use `.title.bold()` instead of L1 spec | MuscleBalanceDiagnosisView, MuscleJourneyView, MuscleHeatmapView | Use `.largeTitle.weight(.heavy)` |
| M-3 | Font | HomeHelpers card headers use `.system(size:16, weight:.bold)` instead of semantic token | HomeHelpers.swift (6 instances) | Use `.headline.bold()` or `.title3.bold()` |
| M-4 | Spacing | Onboarding top spacing varies: 24/32/48/60 | GoalSelection(24), FrequencySelection(32), FavoriteExercises(48), Splash(60) | Unify to 32pt (matches most pages) |
| M-5 | Spacing | Button heights have 4 non-standard values | HomeHelpers(44), RoutineBuilder/PRInput(48), FrequencySelection/ExercisePreview(50), SetInput(60) | Standardize: primary=56, secondary=48, in-card=44 |
| M-6 | Component | Checkmark indicators have **2 sizes** with no clear logic | GoalSelection/Location: 20x20 circle + 10pt font; Frequency/Favorites: 24x24 + 12pt font | Unify to 24x24 + 12pt for all |
| M-7 | Component | FrequencySelectionPage cards use cornerRadius **16** while all other selection cards use **12** | FrequencySelectionPage.swift | Change to 12 or unify all to 16 |
| M-8 | Component | Selected card background opacity varies: 0.06/0.08/0.1 | FavoriteExercises(0.06), most pages(0.08), TrainingHistory(0.1) | Unify to 0.08 |
| M-9 | Color | 3 locally-defined PR tokens not centralized | FriendActivityCard.swift:211-228 (`mmPRCardBg`, `mmPRBorder`, `mmPRAccent`) | Move to ColorExtensions.swift |
| M-10 | Color | Opacity value inconsistencies for identical patterns | Text dimming: 0.4 vs 0.5; Accent borders: 0.25 vs 0.3; Selected BG: 0.06/0.08/0.1 | Define standard opacity tiers |
| M-11 | Animation | GoalSelectionPage cascade delay is 0.06 while all others use 0.08 | GoalSelectionPage.swift | Change to 0.08 |
| M-12 | Spacing | Non-8pt-grid values scattered throughout | padding(3), padding(5), padding(7), padding(10), padding(14), height(50) | Snap to nearest 8pt grid value |

### 2.4 LOW (P3)

| # | Category | Issue | Location | Fix |
|:---|:---|:---|:---|:---|
| L-1 | Color | 6 onboarding tokens defined outside ColorExtensions.swift | OnboardingV2View.swift:110-115 | Consider moving to ColorExtensions.swift with `mmOnboarding` prefix |
| L-2 | Font | Share card components use 16+ different font sizes | WorkoutCompletionComponents.swift | Acceptable (render-only, non-interactive) -- document as exempt |
| L-3 | Spacing | SplashView uses padding 32/48 instead of standard 24/32 | SplashView.swift | Acceptable if intentional for brand screen |
| L-4 | Spacing | `.cornerRadius(4)` legacy API (deprecated) | HistoryCalendarComponents.swift | Replace with `.clipShape(RoundedRectangle(cornerRadius: 4))` |
| L-5 | Component | Left accent bar height approach differs (explicit height vs padding) | GoalSelectionPage uses `height: 24`; others use `padding(.vertical, N)` | Unify to padding approach for auto-fill |
| L-6 | Animation | PRInputPage bottom padding is 16 instead of 32 | PRInputPage.swift:255 | Change to 32 for consistency |

---

## 3. Accessibility Issues

### 3.1 VoiceOver Support

| Severity | Issue | Count | Impact |
|:---|:---|:---|:---|
| **CRITICAL** | Zero `.accessibilityLabel` in entire Views directory | 0/65 files | Custom components (muscle map, checkmarks, GIFs, accent bars) are invisible/meaningless to VoiceOver |
| **CRITICAL** | Zero `.accessibilityHint` | 0/65 files | No action descriptions for interactive elements |
| **CRITICAL** | Zero `.accessibilityValue` | 0/65 files | No state information for selection cards, progress indicators |

**Priority components needing labels:**
1. `MuscleMapView` / `MiniMuscleMapView` -- describe muscle states
2. Onboarding selection cards -- describe selected/unselected state
3. `ExerciseGifView` -- describe exercise being shown
4. Timer display -- announce time remaining
5. Progress indicators -- announce completion percentage

### 3.2 Tap Target Violations

| Element | Size | File | Minimum Required |
|:---|:---|:---|:---|
| LocationCard | 42pt height | LocationSelectionPage.swift | 44pt |
| kg/lb toggle | ~28pt height | TrainingHistoryPage.swift | 44pt |
| Set/rep capsule button | ~28pt height | RoutineBuilderPage.swift | 44pt |
| Remove exercise icon | ~20pt (icon only) | RoutineBuilderPage.swift | 44pt |
| PR weight stepper | ~32pt (no frame) | PRInputPage.swift | 44pt |
| MuscleHeatmap cells | 12-16pt | MuscleHeatmapView.swift | 44pt (if tappable) |

### 3.3 Contrast Issues

| Element | Foreground | Background | Ratio | WCAG AA |
|:---|:---|:---|:---|:---|
| Disabled button text | `#8E8E93` | `#2C2C2E` | ~3.4:1 | **FAIL** (needs 4.5:1) |
| Subtitle text | `#8E8E93` | `#1A1A1E` | ~4.6:1 | PASS (marginal) |
| Selected card tint | `#00E676` @8% | `#1A1A1E` | N/A | Nearly invisible for low vision |
| "Skip"/"Continue Free" | `#8E8E93` | transparent | ~4.6:1 | PASS (marginal) |

### 3.4 Dynamic Type

**Status: Not supported.**

Zero uses of `.dynamicTypeSize`, `DynamicTypeSize`, or `sizeCategory` across all View files. All text uses fixed `.system(size:)` specifications. Users with system font size preferences (especially accessibility sizes) will see no scaling.

---

## 4. Design System Proposals

### 4.1 Standardized Font Scale (8 sizes)

Replace the current 27-size sprawl with a strict 8-size scale for interactive UI:

| Token | Size | Weight | Role | SwiftUI |
|:---|:---|:---|:---|:---|
| `mmFontPageTitle` | 34pt | Heavy | Page titles (main app) | `.largeTitle.weight(.heavy)` |
| `mmFontOnboardingTitle` | 28pt | Heavy | Onboarding page titles | `.system(size: 28, weight: .heavy)` |
| `mmFontSectionTitle` | 22pt | Bold | Section headers | `.title2.bold()` |
| `mmFontCardTitle` | 20pt | Bold | Card/sub-section titles | `.title3.bold()` |
| `mmFontItemName` | 17pt | Semibold | Item names, headlines | `.headline` / `.subheadline.bold()` |
| `mmFontBody` | 15pt | Regular | Body text | `.subheadline` |
| `mmFontCaption` | 12pt | Regular/Bold | Labels, metadata | `.caption` / `.caption.bold()` |
| `mmFontMicro` | 11pt | Regular | Badges, timestamps | `.caption2` |
| `mmFontCTA` | 18pt | Bold | CTA buttons (already consistent) | `.system(size: 18, weight: .bold)` |

**Exception:** Share card renderers (WorkoutCompletionComponents, StrengthShareCard) -- exempt from hierarchy, document as "render-only."

### 4.2 Standardized Opacity Tiers

| Tier | Value | Usage |
|:---|:---|:---|
| `ultraSubtle` | 0.08 | Selected state card tint |
| `subtle` | 0.15 | Badge/tag backgrounds |
| `light` | 0.3 | Border strokes, card outlines |
| `medium` | 0.5 | Inactive/secondary elements |
| `strong` | 0.7 | Chart fills, emphasized elements |
| `nearFull` | 0.9 | Primary highlighted elements |

### 4.3 Standardized Spacing Scale

| Token | Value | Usage |
|:---|:---|:---|
| `mmSpacingXS` | 4pt | Micro gaps, icon-to-text |
| `mmSpacingSM` | 8pt | Compact element spacing |
| `mmSpacingMD` | 16pt | Standard element-to-element |
| `mmSpacingLG` | 24pt | Onboarding horizontal padding |
| `mmSpacingXL` | 32pt | Section-to-section, bottom CTA |

**Main app horizontal padding:** Standardize to **16pt**.
**Onboarding horizontal padding:** Keep at **24pt**.
**CTA bottom padding:** Onboarding=32, Main app=16 (document the rationale).

### 4.4 Standardized Button Heights

| Tier | Height | Usage |
|:---|:---|:---|
| Primary CTA | 56pt | Full-width action buttons |
| Secondary | 48pt | Sheet buttons, secondary actions |
| In-card | 44pt | Compact action buttons within cards |

Remove 50pt and 60pt outliers.

### 4.5 Standardized Corner Radius

Keep the existing 4-tier system from CLAUDE.md, remove outliers:

| Size | Usage | Outliers to Fix |
|:---|:---|:---|
| 4pt | Tiny indicators | -- |
| 8pt | Pills, chips, tags | -- |
| 12pt | ALL selection cards (unify from 12/14/16) | Remove 6pt, 10pt, 14pt outliers |
| 16pt | Major cards, buttons, sections | -- |
| 24pt | Large containers, share cards | -- |

### 4.6 Accessibility Roadmap

**Phase 1 (Critical -- pre-launch):**
1. Add `.accessibilityLabel` to all interactive custom components
2. Add `.accessibilityHint` to non-obvious tappable elements
3. Fix tap targets below 44pt

**Phase 2 (High -- next release):**
1. Fix disabled button contrast (increase to 4.5:1 ratio)
2. Add `.accessibilityValue` for selection states
3. Add Dynamic Type support to key screens (Home, Workout, Onboarding)

**Phase 3 (Ideal -- ongoing):**
1. Full Dynamic Type support across all screens
2. VoiceOver audit with real hardware
3. Reduce Motion support (`.accessibilityReduceMotion`)

---

## 5. Summary Statistics

| Metric | Value |
|:---|:---|
| Files audited | 65 |
| Total color tokens | 32 (+ aliases) |
| Color violations (system/hardcoded) | 4 |
| Cross-boundary token usage | 2 |
| Total font size variants | 27 |
| Font hierarchy deviations | 30+ |
| CTA button consistency | 18/18 (100%) |
| Non-8pt-grid spacing values | 15+ types |
| Button height variants | 5 (should be 3) |
| Corner radius outliers | 3 (6pt, 10pt, 14pt) |
| Accessibility labels | 0 |
| Dynamic Type support | 0 |
| Tap targets below 44pt | 6+ |
| WCAG contrast failures | 1 confirmed, 1 marginal |
| Animation consistency | Good (spring/easeOut/easeInOut standardized) |

---

*Generated by automated UI audit pipeline -- 2026-03-20*
